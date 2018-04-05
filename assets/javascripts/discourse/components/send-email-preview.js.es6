import Ember from 'ember';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default Ember.Component.extend({
  classNames: ['send-email-preview'],

  actions: {
    submit() {
      ajax('/admin/plugins/site-report/preview.json').then(() => {
        bootbox.alert(I18n.t("site_report.preview.sent"));
      }).catch(popupAjaxError);
    }
  }
});
