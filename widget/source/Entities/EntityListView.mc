using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Timer;

class EntityListController {
  hidden var _mEntities;
  hidden var _mHassModel;
  hidden var _mIndex;

  function initialize(hassModel, types) {
    _mHassModel = hassModel;

    if (types != null) {
      _mEntities = hassModel.getEntitiesByTypes(types);
    } else {
      _mEntities = hassModel.getEntities();
    }

    _mIndex = 0;
  }

  function getCurrentEntity() {
    if (_mEntities.size() == 0) {
      return null;
    }

    return _mEntities[_mIndex];
  }

  function setIndex(index) {
    if (!(index instanceof Number)) {
      throw new InvalidValueException();
    }
    _mIndex = index;
  }

  function getIndex() {
    return _mIndex;
  }

  function getCount() {
    return _mEntities.size();
  }

  function toggleEntity(entity) {
    _mHassModel.toggleEntityState(entity);
  }
}

class EntityListDelegate extends Ui.BehaviorDelegate {
  hidden var _mController;

  function initialize(controller) {
    BehaviorDelegate.initialize();
    _mController = controller;
  }

  function onMenu() {
    App.getApp().menu.showRootMenu();
  }

  function onSelect() {
    var entity = _mController.getCurrentEntity();
    _mController.toggleEntity(entity);
  }

  function onNextPage() {
    var index = _mController.getIndex();
    var count = _mController.getCount();

    index += 1;

    if (index > count - 1) {
      index = 0;
    }

    _mController.setIndex(index);
    Ui.requestUpdate();
  }

  function onPreviousPage() {
    var index = _mController.getIndex();
    var count = _mController.getCount();

    index -= 1;

    if (index < 0) {
      index = count - 1;
    }

    _mController.setIndex(index);
    Ui.requestUpdate();

  }
}

class EntityListView extends Ui.View {
  hidden var _mController;
  hidden var _mLastIndex;
  hidden var _mTimer;
  hidden var _mTimerActive;
  hidden var _mShowBar;

  function initialize(controller) {
    View.initialize();
    _mController = controller;
    _mLastIndex = null;
    _mTimer = new Timer.Timer();
    _mTimerActive = false;
    _mShowBar = false;
  }

  function onLayout(dc) {
    setLayout([]);
  }

  function drawNoEntityText(dc) {
    var vh = dc.getHeight();
    var vw = dc.getWidth();

    var cvh = vh / 2;
    var cvw = vw / 2;

    var SmileySad = Ui.loadResource(Rez.Drawables.SmileySad);

    dc.drawBitmap(
      cvw - (SmileySad.getHeight() / 2),
      (vh * 0.3) - (SmileySad.getHeight() / 2),
      SmileySad
    );

    var font = Graphics.FONT_MEDIUM;
    var text = Ui.loadResource(Rez.Strings.NoEntities);
    text = Graphics.fitTextToArea(text, font, vw * 0.9, vh * 0.9, true);

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.drawText(cvh, cvw, font, text, Graphics.TEXT_JUSTIFY_CENTER);
  }

  function drawEntityText(dc, entity) {
    var vh = dc.getHeight();
    var vw = dc.getWidth();

    var cvh = vh / 2;
    var cvw = vw / 2;

    var fontHeight = vh * 0.3;
    var fontWidth = vw * 0.80;

    var text = entity.getName();

    var fonts = [Graphics.FONT_MEDIUM, Graphics.FONT_TINY, Graphics.FONT_XTINY];
    var font = fonts[0];

    for (var i = 0; i < fonts.size(); i++) {
        var truncate = i == fonts.size() - 1;
        System.println(truncate);
        var tempText = Graphics.fitTextToArea(text, fonts[i], fontWidth, fontHeight, truncate);

        if (tempText != null) {
            text = tempText;
            font = fonts[i];
            break;
        }
    }

    dc.drawText(cvh, cvw * 1.1, font, text, Graphics.TEXT_JUSTIFY_CENTER);
  }

  function drawIcon(dc, entity) {
    var vh = dc.getHeight();
    var vw = dc.getWidth();

    var cvw = vw / 2;

    var drawable = null;

    var type = entity.getType();
    var state = entity.getState();

    if (type == Entity.TYPE_LIGHT) {
        if (state == Entity.STATE_ON) {
            drawable = WatchUi.loadResource(Rez.Drawables.LightOn);
        } else if (state == Entity.STATE_OFF) {
            drawable = WatchUi.loadResource(Rez.Drawables.LightOff);
        }
    } else if (type == Entity.TYPE_SWITCH) {
        if (state == Entity.STATE_ON) {
            drawable = WatchUi.loadResource(Rez.Drawables.SwitchOn);
        } else if (state == Entity.STATE_OFF) {
            drawable = WatchUi.loadResource(Rez.Drawables.SwitchOff);
        }
    } else if (type == Entity.TYPE_SCENE) {
      drawable = WatchUi.loadResource(Rez.Drawables.Scene);
    }

    if (drawable == null) {
        drawable = WatchUi.loadResource(Rez.Drawables.Unknown);
    }

    dc.drawBitmap(
      cvw - (drawable.getHeight() / 2),
      (vh * 0.3) - (drawable.getHeight() / 2),
      drawable
    );
  }

  function drawPageBar(dc) {
    var numEntities = _mController.getCount();
    var currentIndex = _mController.getIndex();

    var vh = dc.getHeight();
    var vw = dc.getWidth();

    var cvh = vh / 2;
    var cvw = vw / 2;

    var radius = cvh - 10;

    var attr = Graphics.ARC_COUNTER_CLOCKWISE;

    var padding = 1;
    var topDegreeStart = 130;
    var bottomDegreeEnd = 230;

    var barSize = ((bottomDegreeEnd - padding) - (topDegreeStart + padding)) / numEntities;

    var barStart = (topDegreeStart + padding) + (barSize * currentIndex);

    System.println(barStart);

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.setPenWidth(10);
    dc.drawArc(cvw, cvh, radius, attr, topDegreeStart, bottomDegreeEnd);

    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.setPenWidth(6);
    dc.drawArc(cvw, cvh, radius, attr, barStart, barStart + barSize);
  }

  function onTimerDone() {
    _mTimerActive = false;
    _mShowBar = false;
    Ui.requestUpdate();
  }

  function shouldShowBar() {
    var index = _mController.getIndex();
    System.println("shouldShowBar()");
    if (_mTimerActive && _mShowBar == true) {
      return;
    }

    if (_mLastIndex != index) {
      if (_mTimerActive) {
        _mTimer.stop();
      }
      System.println("starting timer");
      _mShowBar = true;
      _mTimer.start(method(:onTimerDone), 1000, false);
    }

    _mLastIndex = index;
  }

  function onUpdate(dc) {
    View.onUpdate(dc);

    var entity = _mController.getCurrentEntity();

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();

    if (entity == null) {
      drawNoEntityText(dc);
      return;
    }

    shouldShowBar();

    drawEntityText(dc, entity);
    drawIcon(dc, entity);

    if (_mShowBar) {
      drawPageBar(dc);
    }

    return;



    var WHITE = Graphics.COLOR_WHITE;
    var BLACK = Graphics.COLOR_BLACK;
  }
}