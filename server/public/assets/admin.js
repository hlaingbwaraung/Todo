/* HappyHome Admin — vanilla JS helpers (no external dependencies). */
(function () {
  'use strict';

  // Confirm dialogs: <form data-confirm="..."> and buttons with data-confirm.
  document.addEventListener('submit', function (event) {
    var form = event.target;
    var message = form.getAttribute('data-confirm');
    // A submit button inside the form may carry its own confirmation
    // (e.g. per-image delete buttons using formaction).
    var submitter = event.submitter;
    if (submitter && submitter.getAttribute('data-confirm')) {
      message = submitter.getAttribute('data-confirm');
    }
    if (message && !window.confirm(message)) {
      event.preventDefault();
    }
  }, true);

  // Auto-submit selects (status workflows): <select data-autosubmit>
  document.addEventListener('change', function (event) {
    var el = event.target;
    if (el.matches('select[data-autosubmit]') && el.form) {
      el.form.submit();
    }
  });

  // Image upload preview: <input type="file" data-preview="targetId">
  document.addEventListener('change', function (event) {
    var input = event.target;
    if (!input.matches('input[type="file"][data-preview]')) return;
    var target = document.getElementById(input.getAttribute('data-preview'));
    if (!target) return;
    target.innerHTML = '';
    Array.prototype.forEach.call(input.files || [], function (file) {
      if (!/^image\//.test(file.type)) return;
      var img = document.createElement('img');
      img.alt = file.name;
      img.src = URL.createObjectURL(file);
      img.onload = function () { URL.revokeObjectURL(img.src); };
      target.appendChild(img);
    });
  });
})();
