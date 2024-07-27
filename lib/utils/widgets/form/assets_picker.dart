import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/defer.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:flutter/material.dart';

class AssetsList extends StatefulWidget {
  final ScrollController? scrollController;
  final ValueNotifier<AssetItem?> asset = ValueNotifier<AssetItem?>(null);
  final TextEditingController controller = TextEditingController();
  final void Function(String? asset) onSelect;
  final String? base;

  AssetsList(this.onSelect, {super.key, this.base, AssetItem? initial, this.scrollController}) {
    asset.value = initial;
  }

  @override
  State<StatefulWidget> createState() {
    return AssetsListState();
  }

  void setSearch(String search) {
    controller.text = search;
  }

  void setAsset(AssetItem asset) {
    this.asset.value = asset;
  }
}

class AssetsListState extends State<AssetsList> {
  String? search;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            child: TextField(
              controller: widget.controller,
              autocorrect: true,
              decoration: InputDecoration(suffixIcon: const Icon(Icons.search), hintText: Language.of(context).search),
            )),
        SizedBox(
          height: ImageFormat.png96x96.height,
          child: Scrollbar(
            controller: widget.scrollController,
            child: ApiListView(
              oddEven: false,
              padding: const EdgeInsets.all(5),
              controller: widget.scrollController,
              scrollDirection: Axis.horizontal,
              request: (String? paging) async {
                return Result(
                  await Api.get(
                    "/regnum${widget.base != null ? '/${widget.base}' : ''}/assets?q=${Uri.encodeComponent(search ?? '')}",
                    paging: paging,
                  ),
                );
              },
              header: widget.asset.value != null
                  ? AssetView(
                      image: widget.asset.value!.src,
                      onSelect: () {
                        setState(() {
                          widget.asset.value = null;
                        });
                      },
                      selected: true,
                    )
                  : null,
              getView: (BuildContext context, Json item, index) {
                AssetItem item_ = AssetItem(item.id!, item['src']);
                if (widget.asset.value != null && item_.id == widget.asset.value!.id) {
                  return const SizedBox.shrink();
                }
                return AssetView(
                  image: item_.src,
                  onSelect: () {
                    setState(() {
                      widget.asset.value = item_;
                    });
                  },
                  selected: widget.asset.value == item_,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  final Deferrer deferrer = Deferrer(700);

  void setSearch() {
    deferrer.defer(() {
      if (search != widget.controller.text) {
        setState(() {
          search = widget.controller.text;
        });
      }
    });
  }

  void setAsset() {
    widget.onSelect(widget.asset.value?.id);
  }

  @override
  void initState() {
    super.initState();
    widget.asset.addListener(setAsset);
    widget.controller.addListener(setSearch);
  }

  @override
  void dispose() {
    widget.asset.removeListener(setAsset);
    widget.controller.removeListener(setSearch);
    super.dispose();
  }
}

class AssetView extends StatelessWidget {
  final bool selected;
  final String image;
  final void Function() onSelect;

  const AssetView({super.key, this.selected = false, required this.image, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Colors.grey[350] : Colors.white,
      elevation: selected ? 1 : 3,
      child: AspectRatio(
        aspectRatio: 1,
        child: ImageWidget.src(image,
            format: ImageFormat.png96x96,
            loadingBuilder: (context, child) => InkWell(
                  onTap: onSelect,
                  customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(padding: const EdgeInsets.all(10), child: child),
                )),
      ),
    );
  }
}

class AssetItem {
  final String id;
  final String src;

  AssetItem(this.id, this.src);

  @override
  bool operator ==(Object other) {
    return other is AssetItem && other.id == id && other.src == src;
  }

  @override
  int get hashCode => Object.hash(id, src);
}
