<template>
    <div class="home">
        <SelectTable v-if="loaded"
                     :selections="selections" />
        <span v-else>
            Loading...
        </span>
    </div>
</template>

<script>
// @ is an alias to /src
import SelectTable from '@/components/SelectTable.vue'
import { mapActions, mapGetters, mapState } from 'vuex';

export default {
    name: 'Select',
    components: {
        SelectTable
    },
    props: {
        editingAttendee: String,
        event: String
    },
    computed: {
        ...mapState([
            'selections',
        ]),
        ...mapGetters([
            'loaded'
        ])
    },
    created() {
        this.fetchData();
    },
    methods: {
        ...mapActions([
            'getEventData'
        ]),
        fetchData() {
            this.getEventData({
                event: this.event,
                editor: this.editingAttendee
            });
        }
    }
}
</script>
