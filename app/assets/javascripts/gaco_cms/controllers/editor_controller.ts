import { Controller } from '@hotwired/stimulus';

// Sample: = f.text_area :template, class: 'form-control', data: { controller: 'gaco-cms-editor', height: '400' }
export default class extends Controller {
  declare element: HTMLTextAreaElement|HTMLInputElement;

  connect() {
  	const attrController = this.element.getAttribute('data-controller');
  	const isTranslatable = attrController.includes('gaco-cms-translatable');
  	if (!isTranslatable) this.buildEditor();
  }

	// source code: https://www.tiny.cloud/docs/demo/file-picker/
	buildEditor() {
		const that = this;
		tinyMCE.baseURL = "/assets/gaco_cms/tinymce";
		tinymce.init({
			selector: `#${this.element.id}`,
			plugins: 'preview importcss searchreplace autolink autosave save directionality code visualblocks visualchars fullscreen image link media template codesample table charmap pagebreak nonbreaking anchor insertdatetime advlist lists wordcount help charmap quickbars emoticons',
			image_title: true,
			automatic_uploads: true,
			images_upload_url: window.gaco_cms_config.upload_path,
			height: this.element.dataset.height || 600,
			content_css: window.gaco_cms_config.editor_css,
			convert_urls: false,
			file_picker_callback: function (cb, value, meta) {
				that.uploadFile(cb, that.calcFormat(meta));
			},
			content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:14px }'
		});
	}

	calcFormat(meta) {
		if (meta.filetype === 'file') return '*/*';
		if (meta.filetype === 'image') return 'image/*';
		if (meta.filetype === 'media') return 'audio/*,video/*';
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
