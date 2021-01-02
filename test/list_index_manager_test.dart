import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:list_index_manager/list_index_manager.dart';

void main() {
  test('测试显示隐藏数组下标', () {
    ListIndexManager manager = ListIndexManager();
    List<IndexItem> compareList = [];
    int length = 50 + Random().nextInt(100);
    List.generate(length, (index) {
      compareList.add(IndexItem(value: index));
    });

    void check() {
      expect(manager.check(), true, reason: manager.toString());
      List<IndexItem> tmpList = compareList.where((element) => !element.hide).toList();
      for (int i = 0; i < tmpList.length; i++) {
        expect(manager.indexOf(i), tmpList[i].value, reason: manager.toString());
      }
    }

    void refreshCompareListHide(int start, int end, bool hide) {
      for (int i = start; i <= end; i++) {
        compareList[i].hide = hide;
      }
    }

    int count = 0;
    do {
      int type = Random().nextInt(4);
      switch (type) {
        case 0:
          {
            int index = Random().nextInt(length);
            manager.hide(index);
            print('hide $index');
            refreshCompareListHide(index, index, true);

            break;
          }
        case 1:
          {
            int index = Random().nextInt(length);
            print('show $index');
            manager.show(index);
            refreshCompareListHide(index, index, false);

            break;
          }
        case 2:
          {
            int start = Random().nextInt(length);
            int end = start + Random().nextInt(length - start);
            print('hide $start->$end');
            manager.hideRange(start, end);
            refreshCompareListHide(start, end, true);

            break;
          }
        case 3:
          {
            int start = Random().nextInt(length);
            int end = start + Random().nextInt(length - start);
            print('show $start->$end');
            manager.showRange(start, end);
            refreshCompareListHide(start, end, false);

            break;
          }
      }
      check();
      print(manager.toString());
      count++;
    } while (count < 100);
  });
}

class IndexItem {
  bool hide;
  final int value;

  IndexItem({this.value, this.hide = false});
}
