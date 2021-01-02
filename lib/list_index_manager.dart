library list_index_manager;

import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';

class _IndexRangeItem<T> extends LinkedListEntry<_IndexRangeItem> {
  int preHideNumber;
  int originStartIndex;

  ///originEndIndex为null代表无限大
  int originEndIndex;

  int _currentStartIndex;
  int get currentStartIndex => _currentStartIndex;

  void resetCurrentStartIndex() {
    _currentStartIndex = originStartIndex - preHideNumber;
  }

  int get length {
    assert(originEndIndex != null);
    return originEndIndex == null ? 0 : originEndIndex - originStartIndex + 1;
  }

  _IndexRangeItem({this.preHideNumber = 0, @required this.originEndIndex, @required this.originStartIndex})
      : assert(preHideNumber != null && originStartIndex != null),
        assert(originEndIndex == null || originEndIndex >= originStartIndex) {
    resetCurrentStartIndex();
  }

  ///判断是否相交
  bool intersect(int start, int end) {
    return (start >= originStartIndex && (originEndIndex == null || start <= originEndIndex)) || (originStartIndex >= start && originStartIndex <= end);
  }

  ///返回在this中不在other中的
  List<_IntegerRange> difference(int startIndex, int endIndex) {
    assert(startIndex != null && endIndex != null);
    assert(() {
      return intersect(startIndex, endIndex);
    }());
    List<_IntegerRange> result = [];
    if (originStartIndex < startIndex) {
      result.add(_IntegerRange(start: originStartIndex, end: startIndex - 1));
    }
    if (originEndIndex == null || originEndIndex > endIndex) {
      result.add(_IntegerRange(start: endIndex + 1, end: originEndIndex));
    }
    return result;
  }

  String toString() {
    return '$originStartIndex-$originEndIndex,preHide:$preHideNumber,currentStartIndex:$currentStartIndex';
  }
}

class _CustomLinkedList<E extends LinkedListEntry<E>> extends LinkedList<E> {
  void forEachFrom(void action(E entry), {E startEntry}) {
    if (startEntry == null || startEntry.list == null) {
      forEach(action);
      return;
    }

    E current = startEntry;
    do {
      action(current);
      current = current.next;
    } while (current != null);
  }
}

class ListIndexManager {
  _IndexRangeItem _preItem;
  _CustomLinkedList<_IndexRangeItem> _indexList = _CustomLinkedList<_IndexRangeItem>();

  ListIndexManager() {
    _init();
  }

  void _init() {
    _indexList.add(_IndexRangeItem(
      originStartIndex: 0,
      preHideNumber: 0,
      originEndIndex: null,
    ));
  }

  int get totalHideNumber => _indexList.isEmpty ? 0 : _indexList.last.preHideNumber;

  ///如果所有都IndexRangeItem的originStartIndex都小于index，则返回_indexList.last
  ///如果所有都IndexRangeItem的originStartIndex都大于index，则返回_indexList.first
  ///返回的_IndexRangeItem的originStartIndex可能等于index
  _IndexRangeItem _findItemBeforeWithOriginIndex(int index) {
    if (_preItem != null && _preItem.list != null) {
      _IndexRangeItem item = _preItem;
      if (_preItem.originStartIndex <= index) {
        do {
          item = item.next;
        } while (item != null && item.originStartIndex <= index);
        return item == null ? _indexList.last : item.previous;
      } else {
        do {
          item = item.previous;
        } while (item != null && item.originStartIndex > index);
        return item == null ? _indexList.first : item;
      }
    } else {
      _IndexRangeItem item = _indexList.firstWhere((element) => element.originStartIndex > index, orElse: () => null);
      return item != null ? (item.previous ?? _indexList.first) : _indexList.last;
    }
  }

  ///如果所有都IndexRangeItem的originStartIndex都小于index，则返回null
  ///如果所有都IndexRangeItem的originStartIndex都大于index，则返回_indexList.first
  ///返回的_IndexRangeItem的originStartIndex不可能等于index
  _IndexRangeItem _findItemAfterWithOriginIndex(int index) {
    if (_preItem != null && _preItem.list != null) {
      _IndexRangeItem item = _preItem;
      if (_preItem.originStartIndex <= index) {
        do {
          item = item.next;
        } while (item != null && item.originStartIndex <= index);
        return item;
      } else {
        do {
          item = item.previous;
        } while (item != null && item.originStartIndex > index);
        return item == null ? _indexList.first : item.next;
      }
    } else {
      _IndexRangeItem item = _indexList.firstWhere((element) => element.originStartIndex > index, orElse: () => null);
      return item;
    }
  }

  _IndexRangeItem _findItemBeforeWithCurrentIndex(int index) {
    assert(index >= _indexList.first.currentStartIndex);
    if (_preItem != null && _preItem.list != null) {
      _IndexRangeItem item = _preItem;
      if (item.currentStartIndex <= index) {
        do {
          item = item.next;
        } while (item != null && item.currentStartIndex <= index);
        return item == null ? _indexList.last : item.previous;
      } else {
        do {
          item = item.previous;
        } while (item != null && item.currentStartIndex > index);
        return item == null ? _indexList.first : item;
      }
    } else {
      _IndexRangeItem item = _indexList.firstWhere((element) => element.currentStartIndex > index, orElse: () => null);
      return item != null ? (item.previous ?? _indexList.first) : _indexList.last;
    }
  }

  /**
   * show和hide相关的方法传递的参数都是旧数据的下标
   */
  void hide(int index) {
    assert(index != null);
    if (_indexList.isEmpty || index < 0) return;
    _IndexRangeItem item = _findItemBeforeWithOriginIndex(index);
    if (item != null && item.originStartIndex <= index) {
      _hideRange(item: item, startIndex: index, endIndex: index);
    }
  }

  void hideRange(int startIndex, int endIndex) {
    assert(startIndex != null && endIndex != null && endIndex >= startIndex);
    if (_indexList.isEmpty || startIndex < 0 || endIndex < startIndex) return;
    _IndexRangeItem item = _findItemBeforeWithOriginIndex(startIndex);
    if (item != null && item.originStartIndex <= endIndex) {
      _hideRange(item: item, startIndex: startIndex, endIndex: endIndex);
    }
  }

  void show(int index) {
    assert(index != null);
    showRange(index, index);
  }

  void showRange(int startIndex, int endIndex) {
    assert(startIndex != null && endIndex != null && endIndex >= startIndex);
    if (_indexList.isEmpty || startIndex < 0 || endIndex < startIndex) return;
    _IndexRangeItem item = _findItemAfterWithOriginIndex(startIndex);
    if (item != null) {
      _showRange(item: item, startIndex: startIndex, endIndex: endIndex);
    }
  }

  void _hideRange({_IndexRangeItem item, int startIndex, int endIndex, int extraHideNumber = 0}) {
    assert(item != null && startIndex != null && endIndex != null && extraHideNumber != null);
    _IndexRangeItem nextItem = item.next;
    bool b = item.intersect(startIndex, endIndex);
    if (b) {
      List<_IntegerRange> rangeList = item.difference(startIndex, endIndex);
      if (rangeList.isEmpty) {
        extraHideNumber += item.length;
        _indexList.remove(item);
      } else {
        int itemEnd = item.originEndIndex;
        _IntegerRange firstRange = rangeList.first;
        extraHideNumber += firstRange.start - item.originStartIndex;
        item.originStartIndex = firstRange.start;
        item.originEndIndex = firstRange.end;
        item.preHideNumber += extraHideNumber;
        item.resetCurrentStartIndex();

        if (rangeList.length == 2) {
          _IntegerRange secondRange = rangeList.last;

          int growintHideNumber = secondRange.start - firstRange.end - 1;
          extraHideNumber += growintHideNumber;
          _IndexRangeItem newItem = _IndexRangeItem(
            preHideNumber: item.preHideNumber + growintHideNumber,
            originEndIndex: secondRange.end,
            originStartIndex: secondRange.start,
          );
          item.insertAfter(newItem);
        } else if (itemEnd != null) {
          extraHideNumber += itemEnd - firstRange.end;
        }
      }
      if (nextItem != null && endIndex >= nextItem.originStartIndex) {
        _hideRange(item: nextItem, startIndex: nextItem.originStartIndex, endIndex: endIndex, extraHideNumber: extraHideNumber);
      } else if (nextItem != null) {
        addPrehideNumberStartFrom(nextItem, extraHideNumber);
      }
    } else if (nextItem != null && endIndex >= nextItem.originStartIndex) {
      _hideRange(item: nextItem, startIndex: startIndex, endIndex: endIndex, extraHideNumber: extraHideNumber);
    }
  }

  void addPrehideNumberStartFrom(_IndexRangeItem item, int extraHideNumber) {
    if (item == null || item.list == null) return;
    _indexList.forEachFrom(
      (entry) {
        entry.preHideNumber += extraHideNumber;
        entry.resetCurrentStartIndex();
      },
      startEntry: item,
    );
  }

  _IntegerRange _hiddenRangeBeforeItem(_IndexRangeItem item) {
    _IndexRangeItem preItem = item?.previous;
    if (preItem != null) {
      if (item.originStartIndex <= preItem.originEndIndex + 1) {
        return null;
      }
      return _IntegerRange(start: preItem.originEndIndex + 1, end: item.originStartIndex - 1);
    } else {
      if (item.originStartIndex == 0) {
        return null;
      }
      return _IntegerRange(start: 0, end: item.originStartIndex - 1);
    }
  }

  void _showRange({_IndexRangeItem item, int startIndex, int endIndex, int extraHideNumber = 0}) {
    assert(item != null && startIndex != null && endIndex != null && extraHideNumber != null);
    _IndexRangeItem nextItem = item.next;
    _IndexRangeItem preItem = item.previous;
    _IntegerRange range = _IntegerRange(start: startIndex, end: endIndex);
    _IntegerRange hideRange = _hiddenRangeBeforeItem(item);
    _IntegerRange intersectionRange = hideRange?.intersection(range);

    if (intersectionRange != null) {
      // 有需要显示的
      if (intersectionRange == hideRange) {
        if (preItem != null) {
          item.originStartIndex = preItem.originStartIndex;
          _indexList.remove(preItem);
        } else {
          item.originStartIndex = intersectionRange.start;
        }
      } else {
        if (intersectionRange.start == hideRange.start) {
          if (preItem != null) {
            preItem.originEndIndex = intersectionRange.end;
          } else {
            item.insertBefore(_IndexRangeItem(originStartIndex: intersectionRange.start, originEndIndex: intersectionRange.end, preHideNumber: intersectionRange.start));
          }
        } else if (intersectionRange.end == hideRange.end) {
          item.originStartIndex = intersectionRange.start;
        } else {
          _IndexRangeItem newItem = _IndexRangeItem(
            originStartIndex: intersectionRange.start,
            originEndIndex: intersectionRange.end,
            preHideNumber: item.preHideNumber + extraHideNumber - (item.originStartIndex - intersectionRange.start),
          );
          item.insertBefore(newItem);
        }
      }
      extraHideNumber -= intersectionRange.length;
    }

    if (extraHideNumber != 0) {
      item.preHideNumber += extraHideNumber;
      item.resetCurrentStartIndex();
    }
    if (nextItem != null && endIndex > item.originEndIndex) {
      _showRange(item: nextItem, startIndex: item.originEndIndex, endIndex: endIndex, extraHideNumber: extraHideNumber);
    } else if (nextItem != null) {
      addPrehideNumberStartFrom(nextItem, extraHideNumber);
    }
  }

  /**
   * index是新数组的下标，该方法返回的是旧数组下标
   */
  int indexOf(int index) {
    assert(index >= _indexList.first.currentStartIndex);
    _preItem = _findItemBeforeWithCurrentIndex(index);
    return _preItem.originStartIndex + index - _preItem.currentStartIndex;
  }

  void clear() {
    _indexList.clear();
    _init();
  }

  String toString() {
    String result = '\n';
    _indexList.forEach((entry) {
      result += entry.toString();
      result += '\n';
    });
    return result;
  }

  @visibleForTesting
  bool check() {
    _IndexRangeItem item = _indexList.first;
    while (item != null) {
      if (item.originStartIndex != item.currentStartIndex + item.preHideNumber || item.preHideNumber < 0) {
        print('error 0:${item.toString()}');
        return false;
      }
      if (item.originEndIndex != null && item.originStartIndex > item.originEndIndex) {
        print('error 1:${item.toString()}');
        return false;
      }
      if (item.next != null) {
        _IndexRangeItem next = item.next;
        if (next.originStartIndex <= item.originEndIndex + 1 || (next.preHideNumber - item.preHideNumber != next.originStartIndex - item.originEndIndex - 1)) {
          print('error 2:${item.toString()}');
          return false;
        }
      }
      item = item.next;
    }
    return true;
  }
}

class _IntegerRange {
  final int start;

  ///end如果是null表示无穷大
  final int end;
  _IntegerRange({this.start, this.end}) : assert(start != null && (end == null || end >= start));

  ///返回在this中不在other中的
  // List<_IntegerRange> difference(_IntegerRange other) {
  //   List<_IntegerRange> result = [];
  //   if (start < other.start) {
  //     result.add(_IntegerRange(start: start, end: other.start - 1));
  //   } else if (end == null || (other.end != null && end > other.end)) {
  //     result.add(_IntegerRange(start: other.end + 1, end: end));
  //   }
  //   return result;
  // }

  ///返回交集
  _IntegerRange intersection(_IntegerRange other) {
    int _start = max(start, other.start);
    int _end = min(end, other.end);
    if (_end < _start) {
      return null;
    } else {
      return _IntegerRange(start: _start, end: _end);
    }
  }

  int get length {
    assert(end != null);
    return end - start + 1;
  }

  bool operator ==(Object other) {
    return other is _IntegerRange && start == other.start && end == other.end;
  }

  @override
  int get hashCode => super.hashCode;
}
