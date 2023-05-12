const reloadTurboFrames = (frames: string[]) => {
	frames.forEach((frameSelector) => {
		const frame = document.body.querySelector<HTMLIFrameElement>(frameSelector);
		if (!frame) return;

		const src = frame.src;
		frame.src = null;
		frame.src = src;
	});
};

const closeActiveModal = () => {
	const modal = document.body.querySelector<HTMLDivElement>(':scope .modal.show');
	if (modal) modal.dispatchEvent(new CustomEvent('close-modal'));
};

// add request header to identify turbo requests
document.addEventListener('turbo:before-fetch-request', (e) => {
	const target = e.target as HTMLElement;
	e.detail.fetchOptions.headers['turbo-request'] = true;

	// by default render response content as content of the turbo-frame
	if (e.target.getAttribute('data-auto-update')) {
		e.detail.fetchOptions.headers['turbo-update'] = e.target.id;
	}

	// TODO: disable form buttons
});

const parseRequestError = async (response) => {
	const result = await response.clone().text();
	const body = result.split('<body>')[1].split('</body>')[0];
	const tpl = `
	  <div data-controller="gaco-cms-modal"
	  data-gaco-cms-modal-size-value="modal-lg text-danger" 
	  data-gaco-cms-modal-self-modal-value="true">${body}</div>
	`;
	document.body.insertAdjacentHTML('beforeend', tpl);
};

document.addEventListener('turbo:before-fetch-response', (e) => {
	const target = e.target as HTMLElement;
	const sourceTarget = e.target as HTMLElement;

	// reset turbo_frame_none src
	if (target.id == 'turbo_frame_none') target.removeAttribute('src');

	const response = e.detail.fetchResponse.response;
	if (response.status != 500) {
		// allow to auto close active modal
		const closeModal = sourceTarget.getAttribute('data-turbo-request-close-modal');
		if (closeModal) closeActiveModal();

		// reload specific turbo-frame
		const frames = sourceTarget.getAttribute('data-turbo-request-reload-frame');
		if (frames) reloadTurboFrames(frames.split(','));
	} else {
		e.preventDefault();
		parseRequestError(response);
	}
});
