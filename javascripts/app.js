var App = {
  months: {
    '1' : 'January',
    '2' : 'February',
    '3' : 'March',
    '4' : 'April',
    '5' : 'May',
    '6' : 'June',
    '7' : 'July',
    '8' : 'August',
    '9' : 'September',
    '10': 'October',
    '11': 'November',
    '12': 'December'
  },

  init: function() {
    this.selectNav();
    this.commits = jQuery('#recent-commits ul');
    new GitHub.Repo('jnunemaker', 'mongomapper').commits('master', this.loadCommits);
  },

  // Formats github api date
  // 2010-06-05T18:25:23-07:00
  formatDate: function(str) {
    var date   = str.split('T')[0],
        pieces = date.split('-'),
        year   = pieces[0],
        month  = pieces[1].replace(/^0/, ''),
        day    = pieces[2].replace(/^0/, '');
    return this.months[month] + ' ' + day + ', ' + year;
  },

  loadCommits: function(commits) {
    var contents = '';
    for(var i=0; i < 3; i++) {
      var commit = commits[i];
      contents += '<li>';
      contents +=   '<a href="http://github.com' + commit.url + '">';
      contents +=     commit.message;
      contents +=   '</a>';
      contents +=   '<span>' + App.formatDate(commit.committed_date) + '</span>';
      contents += '</li>';
    }
    App.commits.append(contents);
  },

  selectNav: function() {
    $('#nav a').each(function() {
      if(window.location.pathname.indexOf(this.getAttribute('href')) == 0) {
        $('#nav a.current').removeClass('current');
        $(this).addClass('current');
      }
    });
  }
};

jQuery(function() {
  App.init();
});