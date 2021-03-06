$('#form').validator({
    custom: {
        'ppolicy': function($el) {
                if(! $el.prop('required') && $el.val() == 0){
                    return true;
                };
                var $ret = 'PPolicy error';
                $.ajax({
                  url: '/checkppolicy',
                  dataType: 'json',
                  async: false,
                  data: 'pwd=' + $el.val(),
                  success: function(data) {
                    $ret = data;
                  }
                });
                this.options.errors['ppolicy'] = $ret['reason'];
                return $ret['match'];
	}
    },
    errors: {
        'ppolicy': 'PPolicy error',
    }
})
