import { Controller } from '@hotwired/stimulus';

// Sample: = f.text_area :template, class: 'form-control', data: { controller: 'gaco-cms-editor', height: '400' }
export default class extends Controller {
  declare element: HTMLTextAreaElement|HTMLInputElement;

	initialize() {
  	const attrController = this.element.getAttribute('data-controller');
  	const isTranslatable = attrController.includes('gaco-cms-translatable');
  	if (!isTranslatable) this.buildEditor();
  }

	// source code: https://www.tiny.cloud/docs/demo/file-picker/
	buildEditor() {
		const that = this;
		tinyMCE.baseURL = "/gaco_cms/tinymce";
		tinymce.init({
			selector: `#${this.element.id}`,
			plugins: 'advlist autolink lists link image charmap preview anchor searchreplace visualblocks code fullscreen insertdatetime media table paste',
			toolbar: 'undo redo | bold italic underline strikethrough | fontselect fontsizeselect formatselect | alignleft aligncenter alignright alignjustify | outdent indent |  numlist bullist checklist | forecolor backcolor casechange permanentpen formatpainter removeformat | pagebreak | charmap emoticons | fullscreen  preview | insertfile image media pageembed template link anchor codesample | a11ycheck ltr rtl',
			automatic_uploads: true,
			images_upload_url: window.gaco_cms_config.upload_path,
			height: this.element.dataset.height || 600,
			content_css: window.gaco_cms_config.editor_css,
			convert_urls: false,
			file_picker_callback: function (cb, value, meta) {
				that.uploadFile(cb, that.calcFormat(meta));
			},
		});
	}

	calcFormat(meta) {
		if (meta.filetype === 'file') return '*/*';
		if (meta.filetype === 'image') return 'image/*';
		if (meta.filetype === 'media') return 'audio/*,video/*';

		return '*/*';
	}

	uploadFile(cb, format) {
		var input = document.createElement('input');
		input.setAttribute('type', 'file');
		input.setAttribute('accept', format);
		input.onchange = function () {
			var file = this.files[0];
			var reader = new FileReader();
			reader.onload = function () {
				var id = 'blobid' + (new Date()).getTime();
				var blobCache =  tinymce.activeEditor.editorUpload.blobCache;
				var base64 = reader.result.split(',')[1];
				var blobInfo = blobCache.create(id, file, base64);
				blobCache.add(blobInfo);
				cb(blobInfo.blobUri(), { title: file.name });
			};
			reader.readAsDataURL(file);
		};
		input.click();
	}
}
