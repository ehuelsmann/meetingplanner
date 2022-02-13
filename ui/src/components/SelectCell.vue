<template>
    <span class="input">
        <input type="checkbox"
               @input.prevent="handleEvent"
               :checked="selection"
               :disabled="disabled">
    </span>
</template>

<script>
import { mapMutations } from 'vuex';

export default {
    name: 'SelectCell',
    props: {
        date: String,
        attendee: String,
        disabled: Boolean,
        selection: Boolean
    },
    methods: {
        ...mapMutations([
            'updateAttendance'
        ]),
        handleEvent(e) {
            this.updateAttendance({
                attendee: this.attendee,
                date: this.date,
                present: e.target.checked
            });
        }
    }
}
</script>
