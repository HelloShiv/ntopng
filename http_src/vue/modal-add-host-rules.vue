<!-- (C) 2022 - ntop.org     -->
<template>
<modal @showed="showed()" ref="modal_id">
  <template v-slot:title>{{title}}</template>
  <template v-slot:body>
    <!-- Target information, here an IP is put -->
    <div class="form-group ms-2 me-2 mt-3 row">
	    <label class="col-form-label col-sm-4" >
        <b>{{_i18n("if_stats_config.target")}}</b>
	    </label>
	    <div class="col-sm-8" >
	      <input ref="host" @change="check_empty_host" class="form-control" type="text" placeholder="A local host IP or '*' for checking all local hosts" required>
	    </div>
    </div>

    <!-- Metric information, here a metric is selected (e.g. DNS traffic) -->
    <div v-if="metrics_ready" class="form-group ms-2 me-2 mt-3 row">
	    <label class="col-form-label col-sm-4" >
        <b>{{_i18n("if_stats_config.metric")}}</b>
	    </label>
      <div class="col-8">
        <SelectSearch v-model:selected_option="selected_metric"
          :options="metric_list">
        </SelectSearch>
      </div>
    </div>

    <!-- Frequency information, a frequency of 1 day, 5 minute or 1 hour for example -->
    <div v-if="metrics_ready" class="form-group ms-2 me-2 mt-3 row">
      <label class="col-form-label col-sm-4" >
        <b>{{_i18n("if_stats_config.frequency")}}</b>
      </label>
      <div class="col-8">
        <SelectSearch v-model:selected_option="selected_frequency"
          :options="frequency_list">
        </SelectSearch>
      </div>
    </div>

    <!-- Threshold information, maximum amount of bytes -->
    <div class="form-group ms-2 me-2 mt-3 row">
	    <label class="col-form-label col-sm-4" >
        <b>{{_i18n("if_stats_config.threshold")}}</b>
	    </label>
      <div class="col-3">
        <SelectSearch v-model:selected_option="metric_type"
          :options="metric_type_list">
        </SelectSearch>  
      </div>
      <div class="col-3">
        <div class="btn-group float-end btn-group-toggle" data-bs-toggle="buttons">
         <template v-if="metric_type.id == 'throughput'" v-for="measure in throughput_threshold_list" >
            <input :value="measure.value" :id="measure.id" type="radio" class="btn-check" autocomplete="off" ref="threshold_measure" name="threshold_measure">
            <label class="btn " :id="measure.id" @click="set_active_radio" v-bind:class="[ measure.active ? 'btn-primary active' : 'btn-secondary' ]" :for="measure.id">{{ measure.label }}</label>
          </template> 
          <template v-else v-for="measure in volume_threshold_list" >
            <input :value="measure.value" :id="measure.id" type="radio" class="btn-check" autocomplete="off" ref="threshold_measure" name="threshold_measure">
            <label class="btn " :id="measure.id" @click="set_active_radio" v-bind:class="[ measure.active ? 'btn-primary active' : 'btn-secondary' ]" :for="measure.id">{{ measure.label }}</label>
          </template>
        </div>
      </div>
      <div class="col-2">
        <input value="1" ref="threshold" type="number" name="threshold" class="form-control" max="1023" min="1" required>
      </div>
    </div>
  </template>
  <template v-slot:footer>
    <NoteList
    :note_list="note_list">
    </NoteList>
    <button type="button" @click="add_" class="btn btn-primary" :class="[ disable_add ? 'disabled' : '' ]">{{_i18n('add')}}</button>
  </template>
</modal>
</template>

<script setup>
import { ref } from "vue";
import { default as modal } from "./modal.vue";
import { default as SelectSearch } from "./select-search.vue";
import { default as NoteList } from "./note-list.vue";
import regexValidation from "../utilities/regex-validation.js";

const input_mac_list = ref("");
const input_trigger_alerts = ref("");

const modal_id = ref(null);
const emit = defineEmits(['add'])
const title = i18n('if_stats_config.add_host_rules_title')
const metrics_ready = ref(false)
const _i18n = (t) => i18n(t);
const metric_list = ref([])
const frequency_list = ref([])
const threshold_measure = ref(null)
const selected_metric = ref({})
const selected_frequency = ref({})
const disable_add = ref(true)
const metric_type = ref({})
const note_list = [
  _i18n('if_stats_config.note_1'),
  _i18n('if_stats_config.note_2'),
  _i18n('if_stats_config.note_3'),
  _i18n('if_stats_config.note_4'),
]

const metric_type_list = [
  { title: _i18n('volume'), label: _i18n('volume'), id: 'volume', active: true },
  { title: _i18n('throughput'), label: _i18n('throughput'), id: 'throughput', active: false },
]

const volume_threshold_list = [
  { title: _i18n('kb'), label: _i18n('kb'), id: 'kb', value: 1024, active: false },
  { title: _i18n('mb'), label: _i18n('mb'), id: 'mb', value: 1048576, active: false },
  { title: _i18n('gb'), label: _i18n('gb'), id: 'gb', value: 1073741824, active: true },
]

const throughput_threshold_list = [
  { title: _i18n('kbps'), label: _i18n('kbps'), id: 'kbps', value: 1000, active: false },
  { title: _i18n('mbps'), label: _i18n('mbps'), id: 'mbps', value: 1000000, active: false },
  { title: _i18n('gbps'), label: _i18n('gbps'), id: 'gbps', value: 1000000000, active: true },
]


const host = ref(null)
const threshold = ref(null)

const showed = () => {};

const props = defineProps({
  metric_list: Array,
  frequency_list: Array,
});

const show = () => {
  modal_id.value.show();
};

const check_empty_host = () => {
  let regex = new RegExp(regexValidation.get_data_pattern('ip'));
  disable_add.value = !(regex.test(host.value.value) || host.value.value === '*');
}

const set_active_radio = (selected_radio) => {
  const id = selected_radio.target.id;

  if(metric_type.value.id == 'throughput') {
    throughput_threshold_list.forEach((measure) => {
      (measure.id === id) ? measure.active = true : measure.active = false;
    })
  } else {
    volume_threshold_list.forEach((measure) => {
      (measure.id === id) ? measure.active = true : measure.active = false;
    })
  }

  Array.from(selected_radio.target.parentElement.children).forEach((element) => {
    /* Check if it's label */
    if(element.tagName == 'LABEL') {
      if(element.id == id) {
        element.classList.remove('btn-secondary')
        element.classList.add('btn-primary')
        element.classList.add('active')
      } else {
        element.classList.add('btn-secondary')
        element.classList.remove('btn-primary')
        element.classList.remove('active')
      }
    }
  })
}

const add_ = () => {
  const tmp_host = host.value.value;
  const tmp_metric_type = metric_type.value.id;
  const tmp_frequency = selected_frequency.value.id;
  const tmp_metric = selected_metric.value.id;
  const tmp_extra_metric = (selected_metric.value.extra_metric) ? selected_metric.value.extra_metric : null
  let basic_value;
  let tmp_threshold;

  if(tmp_metric_type == 'throughput') {
    throughput_threshold_list.forEach((measure) => { if(measure.active) basic_value = measure.value; })
    tmp_threshold = basic_value * parseInt(threshold.value.value) / 8;
    /* The throughput is in bit, the volume in Bytes!! */
  } else {
    volume_threshold_list.forEach((measure) => { if(measure.active) basic_value = measure.value; })
    tmp_threshold = basic_value * parseInt(threshold.value.value);
  }

  emit('add', { 
    host: tmp_host, 
    frequency: tmp_frequency, 
    metric: tmp_metric,
    threshold: tmp_threshold,
    metric_type: tmp_metric_type,
    extra_metric: tmp_extra_metric,
  });
  close();
};

const close = () => {
  modal_id.value.close();
};

const metricsLoaded = (_metric_list) => {
  metrics_ready.value = true;
  metric_list.value = _metric_list;
  frequency_list.value = props.frequency_list;
  selected_frequency.value = frequency_list.value[0];
  selected_metric.value = metric_list.value[0];
}

defineExpose({ show, close, metricsLoaded });


</script>

<style scoped>
</style>
