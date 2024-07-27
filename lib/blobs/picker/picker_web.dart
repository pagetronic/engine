import 'package:engine/api/utils/json.dart';
import 'package:engine/blobs/blob.dart';
import 'package:engine/blobs/picker.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';

class TypedFilePicker implements TypedFilePickerAbstract {
  @override
  Future<Json?> getImageUpload({required ImageSource source, void Function(XFile? file)? onPick}) async {
    ImagePickerPlugin picker = ImagePickerPlugin();
    XFile? file = await picker.getImageFromSource(source: source);
    if (file != null) {
      if (onPick != null) {
        onPick(file);
      }
      return await BlobStore.uploadXFile(file);
    }
    return null;
  }
}
