import 'dart:convert';

import 'package:engine/api/utils/json.dart';
import 'package:engine/blobs/blob.dart';
import 'package:engine/blobs/picker.dart';
import 'package:engine/data/store.dart';
import 'package:image_picker/image_picker.dart' as os;

class TypedFilePicker implements TypedFilePickerAbstract {
  @override
  Future<Json?> getImageUpload({required ImageSource source, void Function(XFile? file)? onPick}) async {
    os.ImagePicker picker = os.ImagePicker();
    XFile? file = await picker.pickImage(source: source);
    if (onPick != null) {
      onPick(file);
    }
    if (file != null) {
      Json? upload = await BlobStore.uploadXFile(file);
      if (upload == null) {
        Json image = Json({
          'id': Store.getId(),
          'file': {
            "type": file.mimeType,
            "size": await file.length(),
            "name": file.name,
            "bytes": base64.encode(await file.readAsBytes())
          }
        });
        (Store.get(StoreType.images)).putData(image);
        return image;
      }
      return upload;
    }
    return null;
  }
}
