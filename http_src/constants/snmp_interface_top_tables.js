import { DataTableUtils } from "../utilities/datatable/sprymedia-datatable-utils";
import formatterUtils from "../utilities/formatter-utils.js";
import { ntopng_utility, ntopng_url_manager } from "../services/context/ntopng_globals_services.js";
import NtopUtils from "../utilities/ntop-utils";


const bytesToSizeFormatter = formatterUtils.getFormatter(formatterUtils.types.bytes.id);
const bpsFormatter = formatterUtils.getFormatter(formatterUtils.types.bps.id);
const handlerIdAddLink = "page-stats-action-link";
const handlerIdJumpHistorical = "page-stats-action-jump-historical";

const top_snmp_interface = {
    table_value: "snmp",
    table_source_def_value_dict: { ifid: true, device: true, if_index: false },
    title: i18n('page_stats.top.top_traffic'),
    view: "top_snmp_ifaces",
    default_sorting_columns: 4,
    default: true,
    
    columns: [{
	columnName: i18n("interface"), name: 'interface', data: 'interface', handlerId: handlerIdAddLink,
	render: function(data, type, service) {
	    let context = this;
	    let handler = {
		handlerId: handlerIdAddLink,
		onClick: function() {
		    let schema = `snmp_if:traffic`;
		    context.add_ts_group_from_source_value_dict("snmp_interface", service.tags, schema);
		},
	    };
	    let label_text = `${data.label} (${data.id})`;
	    return DataTableUtils.createLinkCallback({ text: label_text, handler });
	},
    }, {
	columnName: i18n("page_stats.top.sent"), name: 'sent', data: 'sent', orderable: true,
	render: (data) => {
	    return bytesToSizeFormatter(data);
	    //return NtopUtils.bytesToSize(data)
	},
    }, {
	columnName: i18n("page_stats.top.received"), name: 'received', data: 'rcvd', orderable: true,
	render: (data) => {
	    return bytesToSizeFormatter(data);
	    //return NtopUtils.bytesToSize(data)
	},
    }, {
	columnName: i18n("traffic"), name: 'traffic', data: 'total', orderable: true,
	render: (data) => {
	    return bytesToSizeFormatter(data);
	    //return NtopUtils.bytesToSize(data)
	},
    }, {
	columnName: i18n("percentage"), name: 'traffic_perc', data: 'percentage',
	render: (data) => {
	    const percentage = data.toFixed(1);
	    return NtopUtils.createProgressBar(percentage)
	}
    }, {
	columnName: i18n("page_stats.top.throughput"), name: 'throughput', data: 'throughput', orderable: true,
	render: (data) => {
	    return bpsFormatter(data);
	    //return NtopUtils.bytesToSize(data)
	},
    },],
};

const snmp_interface_top_tables = [top_snmp_interface];

export default snmp_interface_top_tables;
