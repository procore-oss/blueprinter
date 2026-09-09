// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="introduction.html">Introduction</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/index.html">Guide to V2 Changes</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/breaking/index.html">Breaking Changes</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/breaking/rendering.html">Rendering</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/breaking/dsl.html">DSL</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/breaking/configuration.html">Configuration</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/breaking/reflection.html">Reflection</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/breaking/extensions.html">Extensions</a></span></li></ol><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/compatible/index.html">Compatible Changes</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/compatible/rendering-views.html">Rendering views</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/compatible/if-unless-options.html">If/unless options</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/compatible/default_if-option.html">default_if option</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/compatible/field-name-option.html">Field name option</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/compatible/extractor-option.html">Extractor option</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/compatible/dynamic-options.html">Dynamic options</a></span></li></ol><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/new/index.html">New Features</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/new/formatters.html">Formatters</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/new/views-are-blueprints.html">Views are Blueprints</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/new/nested-views.html">Nested views</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/new/partials.html">Partials</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/new/modules.html">Modules</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v2/new/extensions.html">Extensions</a></span></li></ol></li></ol><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/index.html">Building V2 Extensions</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/basics.html">Basics</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/exclude-if-blank.html">Exclude If Blank</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/custom-extractor.html">Custom Extractor</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/blueprint-decorator.html">Blueprint Decorator</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/telemetry.html">Telemetry</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/camelize-fields.html">Camelize Fields</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/yaml-serializer.html">YAML Serializer</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="extensions/performance.html">Performance</a></span></li></ol><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v1.html">Legacy/V1 Docs</a></span></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split('#')[0].split('?')[0];
        if (current_page.endsWith('/')) {
            current_page += 'index.html';
        }
        const links = Array.prototype.slice.call(this.querySelectorAll('a'));
        const l = links.length;
        for (let i = 0; i < l; ++i) {
            const link = links[i];
            const href = link.getAttribute('href');
            if (href && !href.startsWith('#') && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The 'index' page is supposed to alias the first chapter in the book.
            if (link.href === current_page
                || i === 0
                && path_to_root === ''
                && current_page.endsWith('/index.html')) {
                link.classList.add('active');
                let parent = link.parentElement;
                while (parent) {
                    if (parent.tagName === 'LI' && parent.classList.contains('chapter-item')) {
                        parent.classList.add('expanded');
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', e => {
            if (e.target.tagName === 'A') {
                const clientRect = e.target.getBoundingClientRect();
                const sidebarRect = this.getBoundingClientRect();
                sessionStorage.setItem('sidebar-scroll-offset', clientRect.top - sidebarRect.top);
            }
        }, { passive: true });
        const sidebarScrollOffset = sessionStorage.getItem('sidebar-scroll-offset');
        sessionStorage.removeItem('sidebar-scroll-offset');
        if (sidebarScrollOffset !== null) {
            // preserve sidebar scroll position when navigating via links within sidebar
            const activeSection = this.querySelector('.active');
            if (activeSection) {
                const clientRect = activeSection.getBoundingClientRect();
                const sidebarRect = this.getBoundingClientRect();
                const currentOffset = clientRect.top - sidebarRect.top;
                this.scrollTop += currentOffset - parseFloat(sidebarScrollOffset);
            }
        } else {
            // scroll sidebar to current active section when navigating via
            // 'next/previous chapter' buttons
            const activeSection = document.querySelector('#mdbook-sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        const sidebarAnchorToggles = document.querySelectorAll('.chapter-fold-toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(el => {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define('mdbook-sidebar-scrollbox', MDBookSidebarScrollbox);

