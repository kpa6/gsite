var addPicToPreview, buttonError, buttonSuccess, getDomain, trimInput;

getDomain = function() {
  var domain;
  domain = window.location.pathname.split("/");
  return domain[domain.length - 1];
};

trimInput = function(o) {
  return o.val($.trim(o.val()));
};

buttonSuccess = function(o, cb) {
  return $(o).html("<i class='icon-ok icon-white'></i>").delay(2000).queue(function(next) {
    cb();
    return next();
  });
};

buttonError = function(o, cb) {
  return $(o).html("<i class='icon-remove icon-white'></i> Error!").delay(2000).queue(function(next) {
    cb();
    return next();
  });
};

$(".toggle-site").click(function(e) {
  var enabled,
    _this = this;
  if ($(this).hasClass("disabled")) {
    return false;
  }
  $(this).html("<i class='icon-refresh icon-white'></i>");
  $(this).addClass("disabled");
  enabled = $(this).attr("data-enabled") !== "true";
  $.ajax({
    type: 'PUT',
    url: "" + api + "/sites/" + (getDomain()),
    data: {
      enable: enabled
    },
    success: function(err) {
      if (!err) {
        return buttonSuccess(_this, function() {
          if (enabled) {
            return $(_this).html("Suspend").removeClass("disabled btn-success").addClass("btn-danger").attr("data-enabled", true);
          } else {
            return $(_this).html("Activate").removeClass("disabled btn-danger").addClass("btn-success").attr("data-enabled", false);
          }
        });
      } else {
        return buttonError(_this, function() {
          if (enabled) {
            return $(_this).removeClass("disabled").html("Activate");
          } else {
            return $(_this).removeClass("disabled").html("Suspend");
          }
        });
      }
    },
    error: function() {
      return buttonError(_this, function() {
        if (enabled) {
          return $(_this).removeClass("disabled").html("Activate");
        } else {
          return $(_this).removeClass("disabled").html("Suspend");
        }
      });
    }
  });
  return false;
});

$(".save").click(function(e) {
  var changes,
    _this = this;
  if ($(this).hasClass("disabled")) {
    return false;
  }
  $(this).html("<i class='icon-refresh icon-white'></i>");
  $(this).addClass("disabled");
  changes = {};
  $(this).parent().parent().find("input").each(function() {
    trimInput($(this));
    return changes[$(this).attr("name")] = $(this).val();
  });
  $(this).parent().parent().find("textarea").each(function() {
    trimInput($(this));
    return changes[$(this).attr("name")] = $(this).val();
  });
  $(this).parent().parent().find("select").each(function() {
    return changes[$(this).attr("name")] = $(this).val();
  });
  if (changes.domain != null) {
    if (changes.domain.length > 0) {
      $("#inputDomain").parent().parent().removeClass("error");
    } else {
      $("#inputDomain").parent().parent().addClass("error");
      return;
    }
  }
  $.ajax({
    type: 'PUT',
    url: "" + api + "/sites/" + (getDomain()),
    data: changes,
    success: function(err) {
      if (!err) {
        buttonSuccess(_this, function() {
          return $(_this).html("Save").removeClass("disabled");
        });
        if (changes.domain != null) {
          history.pushState({}, '', changes.domain);
          return $('.domain-name').html("" + changes.domain + " <small>(<a href='http://" + changes.domain + "' target='_blank'>visit site</a>)</small>");
        }
      } else {
        return buttonError(_this, function() {
          return $(_this).html("Save").removeClass("disabled");
        });
      }
    },
    error: function() {
      return buttonError(_this, function() {
        return $(_this).html("Save").removeClass("disabled");
      });
    }
  });
  return false;
});

$('#cp1').colorpicker().on('changeColor', function(ev) {
  return $('#inputToolbarTopColor').val(ev.color.toHex());
});

$('#cp2').colorpicker().on('changeColor', function(ev) {
  return $('#inputToolbarBottomColor').val(ev.color.toHex());
});

$('#cp3').colorpicker().on('changeColor', function(ev) {
  return $('#inputBackgroundColor').val(ev.color.toHex());
});

$(document).on(".preview i", "click", function() {
  $(this).parent().parent().find("input").attr("value", null);
  if (!$(this).parent().parent().find(".help-inline").length) {
    $(this).parent().parent().find(".file-upload").after('<span class="help-inline">Press save button below the form to apply changes</span>');
  }
  return $(this).parent().html("");
});

addPicToPreview = function(self, event, link) {
  $(self).attr('value', link);
  $(self).parent().find(".preview").html('<i class="icon-remove icon-white"></i><img src="' + link + '"/>');
  if (!$(self).parent().find(".help-inline").length) {
    return $(self).parent().find(".file-upload").after('<span class="help-inline">Press save button below the form to apply changes</span>');
  }
};
