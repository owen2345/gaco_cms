const requestHeaders = () => {
	const meta1 = document.querySelector('meta[name="csrf-param"]');
	const meta2 = document.querySelector('meta[name="csrf-token"]');
	const res = { xhr: true };
	res[meta1['content']] = meta2['content'];
	res['X-CSRF-Token'] = meta2['content'];
	return res;
}

export const ajaxRequest = async (path, data = {}, method = 'GET', format = 'text') => {
	const reqData = {
		method: method,
		headers: requestHeaders()
	};
	if (method !== 'GET') reqData['body'] = data;
	const response = await fetch(path, reqData);
	const res = await (format == 'json' ? response.json() : response.text());
	return res;
}
