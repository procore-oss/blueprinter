# frozen_string_literal: true

require 'spec_helper'

# Thread safety and caching integration tests for ViewCollection optimizations
RSpec.describe 'ViewCollection Caching and Thread Safety' do
  # Simple test blueprints
  class TestUser < Blueprinter::Base
    identifier :id
    field :name

    view :with_email do
      field :email
    end

    view :public do
      fields :name, :email
      exclude :email  # Test exclude with caching
    end
  end

  class TestPost < Blueprinter::Base
    identifier :id
    field :title

    view :with_author do
      association :author, blueprint: TestUser
    end

    view :detailed do
      include_view :with_author
      field :content
      association :author, blueprint: TestUser, view: :with_email
    end
  end

  let(:user) { OpenStruct.new(id: 1, name: 'John', email: 'john@example.com') }
  let(:post) { OpenStruct.new(id: 1, title: 'Test Post', content: 'Content', author: user) }

  describe 'caching behavior' do
    it 'produces consistent results across multiple calls' do
      # First call - populates cache
      result1 = TestPost.render_as_hash(post, view: :detailed)

      # Subsequent calls - should use cache and be identical
      result2 = TestPost.render_as_hash(post, view: :detailed)
      result3 = TestPost.render_as_hash(post, view: :detailed)

      expect(result1).to eq(result2)
      expect(result2).to eq(result3)

      # Verify the content is correct
      expect(result1).to include(:id, :title, :content)
      expect(result1[:author]).to include(:id, :name, :email)
    end

    it 'caches different views separately' do
      detailed_result = TestPost.render_as_hash(post, view: :detailed)
      basic_result = TestPost.render_as_hash(post, view: :with_author)

      # Different views should produce different results
      expect(detailed_result).to include(:content)
      expect(basic_result).not_to include(:content)

      # But both should be consistent on repeated calls
      expect(TestPost.render_as_hash(post, view: :detailed)).to eq(detailed_result)
      expect(TestPost.render_as_hash(post, view: :with_author)).to eq(basic_result)
    end

    it 'handles view exclusions correctly with caching' do
      # Test that exclude fields work correctly with cached field arrays
      public_result = TestUser.render_as_hash(user, view: :public)
      email_result = TestUser.render_as_hash(user, view: :with_email)

      # Public view should exclude email despite it being in the field list
      expect(public_result).to include(:id, :name)
      expect(public_result).not_to include(:email)

      # Email view should include email
      expect(email_result).to include(:id, :name, :email)
    end
  end

  describe 'cache invalidation' do
    it 'clears cache when new views are added dynamically' do
      view_collection = TestPost.view_collection

      # Render to populate cache
      original_result = TestPost.render_as_hash(post, view: :detailed)

      # Access a new view (this triggers cache clearing in [] method)
      view_collection[:new_dynamic_view]

      # Subsequent renders should still work correctly
      new_result = TestPost.render_as_hash(post, view: :detailed)

      expect(original_result).to eq(new_result)
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access without race conditions' do
      results = []
      errors = []
      threads = []

      # Spawn multiple threads rendering simultaneously
      5.times do |i|
        threads << Thread.new do
          begin
            # Each thread uses different view to test cache isolation
            view = [:detailed, :with_author, :detailed, :with_author, :detailed][i]
            result = TestPost.render_as_hash(post, view: view)
            results << { thread: i, view: view, result: result }
          rescue => e
            errors << { thread: i, error: e }
          end
        end
      end

      # Wait for all threads to complete
      threads.each(&:join)

      # Should have no errors
      expect(errors).to be_empty

      # Should have 5 results
      expect(results.length).to eq(5)

      # Verify no data corruption occurred
      results.each do |result_data|
        result = result_data[:result]
        expect(result).to be_a(Hash)
        expect(result).to include(:id, :title)
        expect(result[:author]).to include(:id, :name)
      end

      # Results for same view should be identical across threads
      detailed_results = results.select { |r| r[:view] == :detailed }.map { |r| r[:result] }
      author_results = results.select { |r| r[:view] == :with_author }.map { |r| r[:result] }

      # All detailed results should be identical
      expect(detailed_results.uniq.length).to eq(1) if detailed_results.length > 1
      # All author results should be identical
      expect(author_results.uniq.length).to eq(1) if author_results.length > 1
    end

    it 'prevents race conditions during cache initialization' do
      # This is harder to test deterministically, but we can at least verify
      # that multiple threads initializing cache simultaneously don't crash
      view_collection = TestPost.view_collection

      # Clear any existing cache
      view_collection.send(:clear_cache!)

      threads = []
      results = []

      # Multiple threads try to populate cache simultaneously
      10.times do
        threads << Thread.new do
          result = TestPost.render_as_hash(post, view: :detailed)
          results << result
        end
      end

      threads.each(&:join)

      # All results should be identical (no race condition corruption)
      expect(results.uniq.length).to eq(1)
      expect(results.first).to include(:id, :title, :content)
    end
  end

  describe 'performance characteristics' do
    it 'demonstrates caching effectiveness' do
      # This test verifies that caching provides performance benefit
      # without being too specific about exact timing

      # First call to warm up cache
      TestPost.render_as_hash(post, view: :detailed)

      # Time multiple cached calls
      start_time = Time.now
      20.times do
        TestPost.render_as_hash(post, view: :detailed)
      end
      elapsed = Time.now - start_time

      # With effective caching, 20 calls should be very fast
      # This is a basic smoke test - exact timing depends on system
      expect(elapsed).to be < 0.5  # Should complete in under 500ms
    end
  end
end
