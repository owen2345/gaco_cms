// add request header to identify turbo requests
document.addEventListener('turbo:before-fetch-request', (e) => {
	const target = e.target as HTMLElement;
	e.detail.fetchOptions.headers['turbo-request'] = true;

	// by default render response content as content of the turbo-frame
	if (e.target.getAttribute('data-auto-update')) {
		e.detail.fetchOptions.headers['turbo-update'] = e.target.id;
	}
});

document.addEventListener('turbo:before-fetch-response', (e) => {
	const target = e.target as HTMLElement;
	if (target.id == 'turbo_frame_none') target.removeAttribute('src');
});


