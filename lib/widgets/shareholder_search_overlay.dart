import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/shareholder_model.dart';

class ShareholderSearchOverlay extends StatefulWidget {
  final String hint;
  final List<ShareholderModel> results;
  final Function(String) onSearch;
  final Function(ShareholderModel?)? onSelected;
  final Widget? selectedItem;
  final bool navigateToDetail;
  final String? initialValue;

  const ShareholderSearchOverlay({
    super.key,
    required this.hint,
    required this.results,
    required this.onSearch,
    this.onSelected,
    this.selectedItem,
    this.navigateToDetail = true,
    this.initialValue,
  });

  @override
  State<ShareholderSearchOverlay> createState() => _ShareholderSearchOverlayState();
}

class _ShareholderSearchOverlayState extends State<ShareholderSearchOverlay> {
  late TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Small delay to allow the overlay's ListTile onTap to fire before the overlay is removed
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  @override
  void didUpdateWidget(ShareholderSearchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.results != oldWidget.results && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _overlayEntry?.markNeedsBuild();
      });
    }
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: widget.results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No shareholders found',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: widget.results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final item = widget.results[index];
                          return ListTile(
                            dense: true,
                            mouseCursor: SystemMouseCursors.click,
                            title: Text(
                              item.fullName,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            ),
                            onTap: () {
                              if (widget.navigateToDetail) {
                                _controller.text = item.fullName;
                              } else {
                                // If it's a picker (like in loan application), clear text after selection
                                _controller.clear();
                                widget.onSearch('');
                              }
                              widget.onSelected?.call(item);
                              _removeOverlay();
                              _focusNode.unfocus();
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              widget.onSearch(value);
              if (value.isNotEmpty) {
                _showOverlay();
              } else {
                _removeOverlay();
              }
              setState(() {}); 
            },
            onTap: () {
              if (_controller.text.isNotEmpty) _showOverlay();
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch('');
                        widget.onSelected?.call(null);
                        _removeOverlay();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC06C4D)),
              ),
            ),
          ),
        ),
        if (widget.selectedItem != null) ...[
          const SizedBox(height: 12),
          widget.selectedItem!,
        ],
      ],
    );
  }
}
