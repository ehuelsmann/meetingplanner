<template>
    <tr>
        <th><span :title="attendee.key">{{ attendee.name }}</span></th>
        <td>{{ attendee.organizer ? "Organizer" : "" }}</td>
        <td v-for="d in dates" :key="d.key" >
            <SelectCell :date="d.key"
                       :attendee="attendee.key"
                       :selection="selections[d.key]"
                       :disabled="isDisabled" />
        </td>
        <td class="link" v-if="editingOrganizer">
            <a :href="`./#/events/${event}/avail/${attendee.key}`">Attendee link</a>
        </td>
    </tr>
</template>

<script>
import SelectCell from '@/components/SelectCell.vue';
import { mapGetters, mapState } from 'vuex';

export default {
    name: 'SelectRow',
    components: {
        SelectCell
    },
    props: {
        attendee: Object,
        selections: Object,
    },
    computed: {
        ...mapState([
            'dates',
            'event'
        ]),
        ...mapGetters([
            'editingAttendee',
            'editingOrganizer'
        ]),
        isDisabled() {
            return (this.attendee.key !== this.editingAttendee);
        }
    }
}
</script>

<style scoped>
.link {
    font-size: smaller;
    vertical-align: center;
}
</style>
