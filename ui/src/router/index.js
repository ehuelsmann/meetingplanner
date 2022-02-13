import { createRouter, createWebHashHistory } from 'vue-router';
import Select from '../views/Select.vue';

const routes = [
    {
        path: '/events/:event/avail/:editingAttendee',
        props: true,
        name: 'Select',
        component: Select
    },
    {
        path: '/events/:event/modify/:editingAttendee',
        props: true,
        name: 'Modify',
        component: () => import(/* webpackChunkName: "modify" */ '../views/Modify.vue')
    },
    {
        path: '/events',
        name: 'Create',
        component: () => import(/* webpackChunkName: "create" */ '../views/Create.vue')
    },
    {
        path: '/about',
        name: 'About',
        // route level code-splitting
        // this generates a separate chunk (about.[hash].js) for this route
        // which is lazy-loaded when the route is visited.
        component: () => import(/* webpackChunkName: "about" */ '../views/About.vue')
    }
];

const router = createRouter({
  history: createWebHashHistory(),
  routes
});

export default router;
