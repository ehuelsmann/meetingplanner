


var app = new Vue({
    el: '#app',
    data: {
        headers: [
        ],
        rows: [
        ],
        alternative: {
        },
        error: null,
        feedback: null
    },
    methods: {
        submit: function(event) {
            let data;
            let self = this;
            this.rows.forEach(row => { if (row.selectable) { data = row } });

            if (data === null) {
                this.error = "Can't find row to update";
            }
            else {
                let datum = window.location.search.substr(1).split("/", 2);

                if (datum.length === 2) {
                    let picker = datum[0];
                    let user = datum[1];

                    console.log(data);
                    axios.post('data?'+picker+'/'+user, data.dates)
                        .then(response => {
                            self.headers = response.data.headers;
                            self.rows = response.data.rows;
                            self.feedback = "Saved!";
                            window.setTimeout(()=>{ self.feedback = null }, 1500);
                        })
                        .catch(error => {
                            if (error.response) {
                                self.error = "Error: " + error.response.data;
                            }
                            else {
                                self.error = error;
                                console.log(error);
                            }
                        });
                }
            }
        },
        selectAlternative: function(event) {
            this.headers = this.alternative.headers;
            this.rows = this.alternative.rows;
        }
    },
    mounted: async function() {
        let self = this;
        let datum = window.location.search.substr(1).split("/", 2);

        if (datum.length === 2) {
            let picker = datum[0];
            let user = datum[1];

            axios.get('data?'+picker+'/'+user)
                .then(response => {
                    self.headers = response.data.headers;
                    self.rows = response.data.rows;
                })
                .catch(error => {
                    if (error.response) {
                        self.error = "Error: " + error.response.data;
                    }
                    else {
                        self.error = error;
                        console.log(error);
                    }
                });
        }
        else {
            self.error = "Can't retrieve appointment data: no appointment specified";
        }
    }
});

