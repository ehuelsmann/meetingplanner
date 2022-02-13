import { createStore } from 'vuex';
import { isEqual, cloneDeep } from 'lodash';

const apiServer = process.env.VUE_APP_API_URL || process.env.BASE_URL;

export default createStore({
    state: {
        event: null,
        dates: null,
        attendees: null,
        selections: null,
        _origSelections: null,
        serverStatus: null
    },
    getters: {
        changed(state) {
            return !isEqual(state.selections, state._origSelections);
        },
        editingAttendee(state) {
            let i = state.attendees.find(attendee => (attendee.state === "editing"));
            return (i) ? i.key : null;
        },
        editingOrganizer(state) {
            let i = state.attendees.find(attendee => (attendee.state === "editing"));
            return (i) ? i.organizer : false;
        },
        hasEvent(state) {
            return state.event;
        },
        loaded(state) {
            return !!(state.selections);
        }
    },
    mutations: {
        appendAttendee(state, attendee) {
            state.attendees.push(attendee);
            state.selections = null;
        },
        appendDate(state, date) {
            state.dates.push(date);
            state.selections = null;
        },
        updateAttendance(state, { attendee, date, present }) {
            state.selections[attendee][date] = present;
        },
        setAttendance(state, newSelections) {
            state.selections = newSelections;
            state._origSelections = cloneDeep(newSelections);
        },
        setEvent(state, newEvent) {
            state.event = newEvent;
        },
        setEventData(state, newData) {
            state.selections = newData.selections;
            state.attendees  = newData.attendees;
            state.dates      = newData.dates;
            state.event      = newData.event;
            state._origSelections = cloneDeep(newData.selections);
        },
        setServerStatus(state, newStatus) {
            state.serverStatus = newStatus;
        }
    },
    actions: {
        async addAttendee({state, getters, commit}, attendee) {
            // fail in case there's no pre-initialized event??
            if (state.event) {
                let editor = getters.editingAttendee;
                let url = `${apiServer}data/${state.event}/attendees/?editor=${editor}`;
                let headers = new Headers();
                headers.set("X-Requested-With", "XMLHttpRequest");
                headers.set("Content-Type", "application/json; charset=UTF-8");

                commit('setServerStatus', 'Adding...');
                let r = await fetch(url,
                                    {
                                        method: "POST",
                                        headers: headers,
                                        body: JSON.stringify({
                                            name: attendee.name
                                        })
                                    });
                if (r.ok) {
                    let attendeeData = await r.json();
                    commit('appendAttendee', attendeeData);
                    commit('setServerStatus', 'Added');
                    return Promise.resolve(attendeeData);
                }
                else {
                    commit('setServerStatus', 'Failed?!');
                    return Promise.reject(r);
                }
            }
            return Promise.reject("No event currently active");
        },
        async addDate({state, getters, commit}, date) {
            // fail in case there's no pre-initialized event??
            if (state.event) {
                let editor = getters.editingAttendee;
                let url = `${apiServer}data/${state.event}/dates/?editor=${editor}`;
                let headers = new Headers();
                headers.set("X-Requested-With", "XMLHttpRequest");
                headers.set("Content-Type", "application/json; charset=UTF-8");

                commit('setServerStatus', 'Adding...');
                let r = await fetch(url,
                                    {
                                        method: "POST",
                                        headers: headers,
                                        body: JSON.stringify({
                                            date: date.date,
                                            time: date.time
                                        })
                                    });
                if (r.ok) {
                    let dateData = await r.json();
                    commit('appendDate', dateData);
                    commit('setServerStatus', 'Added');
                    return Promise.resolve(dateData);
                }
                else {
                    commit('setServerStatus', 'Failed?!');
                    return Promise.reject(r);
                }
            }
            return Promise.reject("No event currently active");
        },
        async createEventData({commit}, details) {
            let url = `${apiServer}data/`;
            let headers = new Headers();
            headers.set("X-Requested-With", "XMLHttpRequest");
            headers.set("Content-Type", "application/json; charset=UTF-8");

            commit('setServerStatus', 'Creating...');
            let r = await fetch(url,
                                {
                                    method: "POST",
                                    headers: headers,
                                    body: JSON.stringify(details)
                                });
            if (r.ok) {
                let eventData = await r.json();
                commit('setEventData', eventData);
                commit('setServerStatus', 'Created');
                return Promise.resolve(eventData);
            }
            else {
                commit('setServerStatus', 'Failed?!');
                return Promise.reject(r);
            }
        },
        clearEventData({commit}) {
            commit('setEventData',
                   {
                       selections: null,
                       attendees: null,
                       dates: null,
                       event: null
                   });
        },
        async getEventData({commit, dispatch}, details) {
            if (!details.event) {
                await dispatch('clearEventData');
                return;
            }

            let editor = details.editor;
            let url = `${apiServer}data/${details.event}?editor=${editor}`;
            let headers = new Headers();
            headers.set("X-Requested-With", "XMLHttpRequest");

            commit('setServerStatus', 'Loading...');
            let r = await fetch(url,
                                {
                                    method: "GET",
                                    headers: headers
                                });
            if (r.ok) {
                let b = await r.json();
                commit('setEventData', b);
                commit('setServerStatus', 'Loaded');
            }
            else {
                let b = await r.json();
                console.log(b);
                commit('setAttendance', null);
                commit('setServerStatus', 'Failed?!');
            }
        },
        async saveAttendance({commit, state, getters}) {
            let editingAttendee = getters.editingAttendee;
            let selections = state.selections[editingAttendee];
            let url = `${apiServer}data/${state.event}?editor=${editingAttendee}`;
            let headers = new Headers();
            headers.set("X-Requested-With", "XMLHttpRequest");
            headers.set("Content-Type", "application/json; charset=UTF-8");

            commit('setServerStatus', 'Saving...');
            let r = await fetch(url,
                                {
                                    method: "PATCH",
                                    headers: headers,
                                    body: JSON.stringify({
                                        "selections": selections
                                    })
                                });
            let b = await r.json();
            commit('setEventData', b);
            commit('setServerStatus', 'Saved');
        }
    },
    modules: {
    }
});
