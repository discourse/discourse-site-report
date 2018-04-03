import Ember from 'ember';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  classNames: ['send-email-preview'],

  actions: {
    submit() {
      ajax('/admin/plugins/site-report/preview.json').catch(popupAjaxError);
    }
  }
});
