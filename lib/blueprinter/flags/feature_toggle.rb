require 'ldclient-rb'

module Blueprinter
  module FeatureToggle
    ENVIRONMENT_KEY = "LAUNCH_DARKLY_API_KEY".freeze

    def self.inject_client(ld_client)
      @client = ld_client
    end

    def self.active?(feature_name, record, default: false)
      if @client
        complete_hash = Hash.new
        custom_hash = build_custom_hash(record)

        complete_hash[:anonymous] = true
        complete_hash[:custom] = custom_hash
        complete_hash[:key] = format_key(custom_hash,
                                         project: record.try(:project),
                                         company: record.try(:company))
        res = @client.variation(
          feature_name.to_s,
          complete_hash,
          # In case the library is not able to query the feature for some
          # reason it will return default arg value.
          default
        )
      else
        default
      end
    end

    private

    def self.format_provider(provider)
      if provider&.respond_to?(:name)
        formatted = provider.name
        # Makes sure we don't break when provider is an unpersisted record.
        formatted += ' (' + provider.id.to_s + ')' if provider.id
        formatted
      end
    end

    def self.format_key(custom_hash, project:, company:)
      if company || project
        [custom_hash[:company], custom_hash[:project], 'user'].compact.join(' ')
      else
        'unknown'
      end
    end

    def self.settings
      base_settings.merge(
        # Keep a persistent connection instead of polling for feature config
        # updates.
        stream: true
      )
    end

    def self.base_settings
      {
        stream_uri: ENV.fetch('LAUNCH_DARKLY_STREAMING_URL', 'https://stream.launchdarkly.com'),
        # The client stored tracking events locally and flushes when when
        # either the internal storage limit or flush interval is reached.
        flush_interval: 60, # seconds
        # Number of tracking events to store locally before flushing them to
        # the server.
        capacity: 65_535, # tracking events
        # Cache store to use for caching HTTP responses from the Launch Darkly
        # servers.
        cache_store: Rails.cache,
        # The connect timeout is used when trying to establish a connection
        # with the Launch Darkly servers. Unfortunately this can't go lower
        # than 1 second.
        connect_timeout: 1, # second
        # The read timeout is used when trying to establish a connection with
        # the Launch Darkly servers. Unfortunately this can't go lower than
        # second.
        read_timeout: 1, # second
        # For the library in offline mode when we're testing so it never
        # tries to send HTTP requests.
        offline: Rails.env.test?,
        # LDClient defaults to Rails.logger but we may want these to have
        # different log levels
        logger: Rails.logger
      }
    end

    def self.build_custom_hash(record)
      custom_hash = Hash.new

      if record.respond_to?(:company_id)
        custom_hash[:company_id] = record.company_id
      end
      if record.respond_to?(:project_id)
        custom_hash[:project_id] = record.project_id
      end
      if record.respond_to?(:company)
        custom_hash[:company] = format_provider(record.company)
      end

      if record.respond_to?(:project)
        custom_hash[:project] = format_provider(record.project)
      end

      # custom_hash[:rails_env] = "development"
      # custom_hash[:company] = "Brickworks (7)"
      # custom_hash[:company_id] = 7
      # custom_hash[:locale] = "en"
      custom_hash[:is_trial] = false
      # custom_hash[:project_id] = 7
      custom_hash
    end
  end
end
