/** @odoo-module **/
import { Component, onMounted } from "@odoo/owl";
import { registry } from "@web/core/registry";

class GanttView1 extends Component {
    static template = "GanttView1";

    setup() {
        this.url = this.props.action?.params?.url;

        onMounted(async () => {
            // Load CSS files
            const cssFiles = [
                ["/pragtech_ppc_ganttchart/static/src/css/platform.css", "all"],
                ["/pragtech_ppc_ganttchart/static/src/css/jquery.dateField.css", "all"],
                ["/pragtech_ppc_ganttchart/static/src/css/gantt.css", "all"],
                ["/pragtech_ppc_ganttchart/static/src/css/ganttPrint.css", "print"],
            ];
            for (const [href, media] of cssFiles) {
                if (!document.querySelector(`link[href="${href}"]`)) {
                    const link = document.createElement("link");
                    link.rel = "stylesheet";
                    link.type = "text/css";
                    link.href = href;
                    link.media = media;
                    document.head.appendChild(link);
                }
            }

            // Load JS libraries sequentially
            const scripts = [
                "/pragtech_ppc_ganttchart/static/src/js/libs/jquery/jquery.livequery.1.1.1.min.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/utilities.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/forms.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/date.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/dialogs.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/layout.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/i18nJs.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/jquery/dateField/jquery.dateField.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/jquery/JST/jquery.JST.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/jquery/svg/jquery.svg.min.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/jquery/svg/jquery.svgdom.1.8.js",
                "/pragtech_ppc_ganttchart/static/src/js/ganttUtilities.js",
                "/pragtech_ppc_ganttchart/static/src/js/ganttTask.js",
                "/pragtech_ppc_ganttchart/static/src/js/ganttDrawerSVG.js",
                "/pragtech_ppc_ganttchart/static/src/js/ganttGridEditor.js",
                "/pragtech_ppc_ganttchart/static/src/js/ganttMaster.js",
                "/pragtech_ppc_ganttchart/static/src/js/libs/jquery/jquery.timers.js",
                "/pragtech_ppc_ganttchart/static/src/js/initialization.js",
                "/pragtech_ppc_ganttchart/static/src/js/assingment.js",
            ];
            for (const src of scripts) {
                await this._loadScript(src);
            }
        });
    }

    _loadScript(src) {
        return new Promise((resolve) => {
            if (document.querySelector(`script[src="${src}"]`)) {
                resolve();
                return;
            }
            const el = document.createElement("script");
            el.src = src;
            el.onload = resolve;
            el.onerror = () => {
                console.warn("Failed to load gantt script:", src);
                resolve();
            };
            document.head.appendChild(el);
        });
    }

    odoo_redirect() {
        if (this.url) {
            window.open(this.url, "_blank");
        }
        this.env.services.action.doAction({ type: "ir.actions.act_window_close" });
    }
}

registry.category("actions").add("gantt_chart", GanttView1);
