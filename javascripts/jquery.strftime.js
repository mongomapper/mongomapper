(function($) {
  $.fn.strftime = function(fmt){
      return this.each(function(){
        d__ = '';

        var a_array = new Array (7);
        a_array[0] ='Sun';
        a_array[1] ='Mon';
        a_array[2] ='Tue';
        a_array[3] ='Wed';
        a_array[4] ='Thu';
        a_array[5] ='Fri';
        a_array[6] ='Sat';

        var A_array = new Array (7);
        A_array[0] ='Sunday';
        A_array[1] ='Monday';
        A_array[2] ='Tuesday';
        A_array[3] ='Wednesday';
        A_array[4] ='Thursday';
        A_array[5] ='Friday';
        A_array[6] ='Saturday';

        var b_array = new Array (12);
        b_array[0] = 'Jan';
        b_array[1] = 'Feb';
        b_array[2] = 'Mar';
        b_array[3] = 'Apr';
        b_array[4] = 'May';
        b_array[5] = 'Jun';
        b_array[6] = 'Jul';
        b_array[7] = 'Aug';
        b_array[8] = 'Sep';
        b_array[9] = 'Oct';
        b_array[10] = 'Nov';
        b_array[11] = 'Dec';

        var B_array = new Array (12);
        B_array[0] = 'January';
        B_array[1] = 'February';
        B_array[2] = 'March';
        B_array[3] = 'April';
        B_array[4] = 'May';
        B_array[5] = 'June';
        B_array[6] = 'July';
        B_array[7] = 'August';
        B_array[8] = 'September';
        B_array[9] = 'October';
        B_array[10] = 'November';
        B_array[11] = 'December';

        // the strftime formating charaters supported by this plugin
        a = a_array[new Date().getDay()]; //mon
        A = A_array[new Date().getDay()];  // Monday
        b = b_array[new Date().getMonth()]; //jan
        B = B_array[new Date().getMonth()]; // January

        function getDate(){
          d = (new Date().getDate()).toString();
          if(d.length < 1){d = '0'+d}
          return d
        }
        function getMonth(){
          m = (new Date().getMonth()+1).toString();
          if(m.length < 1){m = '0'+m}
          return m
        }

        d =  getDate();
        H =  new Date().getHours();
        y =  new Date().getYear();
        Y =  new Date().getFullYear();
        m =  getMonth();
        M =  new Date().getMinutes();
        if(!fmt){
          fmt = '%d/%m/%Y';
        }
        if(fmt){
          f = fmt;
          // pull out the items in fmt
          for(var i =0; i < fmt.length; i++){
            if(fmt[i] == '%'){
              d__ = d__ +eval(fmt[++i]);
            }else{
              d__ = d__ + fmt[i];
            }
          }
        }

        $(this).html(d__);
      });
  };
 })(jQuery);