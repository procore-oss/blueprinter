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
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="introduction.html">Introduction</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="dsl/index.html">Blueprinter DSL</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="dsl/fields.html">Fields</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="dsl/views.html">Views</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="dsl/partials.html">Partials</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="dsl/formatters.html">Formatters</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="dsl/options.html">Options</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="dsl/extensions.html">Extensions</a></span></li></ol><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="rendering.html">Rendering</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="api/index.html">Blueprinter API</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="api/extensions.html">Extensions</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="api/reflection.html">Reflection</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="api/context-objects.html">Context Objects</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="api/fields.html">Fields</a></span></li></ol><li class="chapter-item expanded "><li class="spacer"></li></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="upgrading/index.html">Upgrading</a></span><ol class="section"><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="upgrading/configuration.html">Configuration</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="upgrading/customization.html">Customization</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="upgrading/fields.html">Fields</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="upgrading/rendering.html">Rendering</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="upgrading/reflection.html">Reflection</a></span></li><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="upgrading/extensions.html">Extensions</a></span></li></ol><li class="chapter-item expanded "><span class="chapter-link-wrapper"><a href="v1.html">Legacy/V1 Docs</a></span></li></ol>';
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

