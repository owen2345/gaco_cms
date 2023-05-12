import application from './stimulus';

import TranslatableController from './controllers/translatable_controller';
import EditorController from './controllers/editor_controller';
import DeletableRowController from './controllers/deletable_row_controller';
import FormConfirmController from "./controllers/confirm_controller";
import RepeatableFieldController from './controllers/repeatable_field_controller';
import FileInputController from './controllers/file_input_controller';
import RemoteContentController from './controllers/remote_content_controller';
import ToggleFieldController from './controllers/toggle_field_controller';
import SortableController from './controllers/sortable_controller';
import ModalController from './controllers/modal_controller';

application.register('gaco-cms-translatable', TranslatableController);
application.register('gaco-cms-editor', EditorController);
application.register('gaco-cms-deletable_row', DeletableRowController);
application.register('gaco-cms-repeatable-field', RepeatableFieldController);
application.register('gaco-cms-file-input', FileInputController);
application.register('gaco-cms-remote-content', RemoteContentController);
application.register('gaco-cms-toggle-field', ToggleFieldController);
application.register('gaco-cms-sortable', SortableController);
application.register('gaco-cms-modal', ModalController);
application.register('form-confirm', FormConfirmController);

