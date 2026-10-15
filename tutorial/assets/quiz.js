/* Self-grading quiz (offline). Usage in a guide:
   <section id="quiz"> ... <p class="quiz-score"></p>
   <div class="quiz" data-answer="b">
     <p class="qq">Question…</p>
     <label><input type="radio" value="a"> option A</label>
     <label><input type="radio" value="b"> option B</label>
     <div class="why">Why B is right (and why A is not).</div>
   </div> ...
   data-answer may list several comma-separated answers (use checkboxes instead of radios).
   Load with <script defer src="../assets/quiz.js"></script> and <link rel="stylesheet" href="../assets/quiz.css">. */
document.addEventListener('DOMContentLoaded', function () {
  var qs = [].slice.call(document.querySelectorAll('.quiz'));
  qs.forEach(function (q, i) {
    q.querySelectorAll('input').forEach(function (inp) { inp.name = inp.name || 'quiz' + i; });
    var btn = document.createElement('button');
    btn.type = 'button'; btn.className = 'quiz-check'; btn.textContent = 'Check';
    q.insertBefore(btn, q.querySelector('.why'));
    btn.addEventListener('click', function () {
      var want = q.dataset.answer.split(',').map(function (s) { return s.trim(); }).sort().join(',');
      var got = [].slice.call(q.querySelectorAll('input:checked')).map(function (x) { return x.value; }).sort().join(',');
      if (!got) return;
      q.classList.remove('ok', 'bad');
      q.classList.add(got === want ? 'ok' : 'bad');
      q.querySelectorAll('label').forEach(function (l) {
        var v = l.querySelector('input').value;
        l.classList.toggle('right', want.split(',').indexOf(v) >= 0);
      });
      score();
    });
  });
  function score() {
    var done = document.querySelectorAll('.quiz.ok, .quiz.bad').length;
    var ok = document.querySelectorAll('.quiz.ok').length;
    document.querySelectorAll('.quiz-score').forEach(function (s) {
      s.textContent = 'Score: ' + ok + ' / ' + done + ' answered (' + qs.length + ' total)';
    });
  }
  score();
});
