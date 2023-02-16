document.addEventListener('turbo:before-fetch-request', () => {
  document.getElementById('main-progress-bar').classList.remove('invisible');
});

document.addEventListener('turbo:before-fetch-response', () => {
  document.getElementById('main-progress-bar').classList.add('invisible');
});
