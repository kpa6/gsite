getDomain = ()->
  domain = window.location.pathname.split "/"
  domain[domain.length-1]

trimInput = (o)->
  o.val $.trim o.val()

buttonSuccess = (o, cb)->
  $(o).html("<i class='icon-ok icon-white'></i>").delay(2000).queue (next)->
    cb()
    next()

buttonError = (o, cb)->
  $(o).html("<i class='icon-remove icon-white'></i> Error!").delay(2000).queue (next)->
    cb()
    next()

$(".toggle-site").click (e)->
  if $(@).hasClass "disabled"
    return false
  
  $(@).html "<i class='icon-refresh icon-white'></i>"
  $(@).addClass "disabled"
  
  enabled = $(@).attr("data-enabled") isnt "true"
  
  $.ajax
    type:'PUT'
    url: "#{api}/sites/#{getDomain()}"
    data:
      enable: enabled
    success: (err)=>
      unless err
        buttonSuccess @, ()=>
          if enabled
            $(@).html("Suspend").removeClass("disabled btn-success").addClass("btn-danger").attr "data-enabled", true
          
          else
            $(@).html("Activate").removeClass("disabled btn-danger").addClass("btn-success").attr "data-enabled", false
      
      else
        buttonError @, ()=>
          if enabled
            $(@).removeClass("disabled").html "Activate"
          
          else
            $(@).removeClass("disabled").html "Suspend"
    error: ()=>
      buttonError @, ()=>
        if enabled
          $(@).removeClass("disabled").html "Activate"
        
        else
          $(@).removeClass("disabled").html "Suspend"

  return false

$(".save").click (e)->
  if $(@).hasClass "disabled"
    return false
  
  $(@).html "<i class='icon-refresh icon-white'></i>"
  $(@).addClass "disabled"

  changes = {}

  $(@).parent().parent().find("input").each ()->
    trimInput $ @
    changes[$(@).attr("name")] = $(@).val()
  
  $(@).parent().parent().find("textarea").each ()->
    trimInput $ @
    changes[$(@).attr("name")] = $(@).val()
  
  $(@).parent().parent().find("select").each ()->
    changes[$(@).attr("name")] = $(@).val()

  if changes.domain?
    if changes.domain.length > 0
      $("#inputDomain").parent().parent().removeClass "error"
    
    else
      $("#inputDomain").parent().parent().addClass "error"
      
      return

  $.ajax
    type:'PUT'
    url: "#{api}/sites/#{getDomain()}"
    data: changes
    success: (err)=>
      unless err
        buttonSuccess @, ()=> $(@).html("Save").removeClass("disabled")
        
        if changes.domain?
          history.pushState {}, '', changes.domain
          $('.domain-name').html "#{changes.domain} <small>(<a href='http://#{changes.domain}' target='_blank'>visit site</a>)</small>"
      
      else
        buttonError @, ()=> $(@).html("Save").removeClass("disabled")
    
    error: ()=>
      buttonError @, ()=> $(@).html("Save").removeClass("disabled")

  return false

#color picker
$('#cp1').colorpicker().on 'changeColor', (ev)->
  $('#inputToolbarTopColor').val ev.color.toHex()

$('#cp2').colorpicker().on 'changeColor', (ev)->
  $('#inputToolbarBottomColor').val ev.color.toHex()

$('#cp3').colorpicker().on 'changeColor', (ev)->
  $('#inputBackgroundColor').val ev.color.toHex()


#remove pic
$(document).on ".preview i", "click", ()->
  $(this).parent().parent().find("input").attr("value", null)
  
  unless $(this).parent().parent().find(".help-inline").length
    $(this).parent().parent().find(".file-upload").after '<span class="help-inline">Press save button below the form to apply changes</span>'
  
  $(this).parent().html("")

#add/replace pic
addPicToPreview = (self, event, link)->
  $(self).attr 'value', link
  
  $(self).parent().find(".preview").html '<i class="icon-remove icon-white"></i><img src="' + link + '"/>'
  
  unless $(self).parent().find(".help-inline").length
    $(self).parent().find(".file-upload").after '<span class="help-inline">Press save button below the form to apply changes</span>'