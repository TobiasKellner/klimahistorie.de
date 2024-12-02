$(document).on('shiny:connected', function() {
  var $body = $('body');
  var isCollapsed = $body.hasClass('sidebar-collapse');

  // Initialer Zustand
  Shiny.setInputValue('sidebar_collapsed', isCollapsed);

  // Ereignis beim Ein- und Ausklappen
  $body.on('collapsed.lte.pushmenu', function() {
    Shiny.setInputValue('sidebar_collapsed', true);
  });

  $body.on('shown.lte.pushmenu', function() {
    Shiny.setInputValue('sidebar_collapsed', false);
  });
});


// Kleinerer Titel 'Klimahistorie.de', wenn Sidebar eingeklappt ist
// https://stackoverflow.com/questions/78650811/how-to-display-a-shorter-title-if-the-sidebar-is-collapsed/78654111#78654111
document.addEventListener('DOMContentLoaded', function(event) {
  var element = document.querySelector('body');
  new MutationObserver((mutations) => {
    document.querySelector('.brand-text').innerHTML =
      (mutations[0].target.classList.contains('sidebar-collapse')) ?
      '<span style="font-size: 9px;"><strong>Klimahistorie.de</strong></span>' :
      '<strong>Klimahistorie.de</strong>';
  })
  .observe(element, {
    attributes: true
  });
});





  $(document).on('collapsed.lte.pushmenu', function() {
    $('#button_wrapper').addClass('sidebar-collapsed').removeClass('sidebar-expanded');
    Shiny.setInputValue('sidebarCollapsed', true, {priority: 'event'});
  });
  $(document).on('shown.lte.pushmenu', function() {
    $('#button_wrapper').addClass('sidebar-expanded').removeClass('sidebar-collapsed');
    Shiny.setInputValue('sidebarCollapsed', false, {priority: 'event'});
  });
