
###
The flyout showing the content of each step.

This is the base class containing most of the logic. Can extend for different
tooltip implementations.
###
class Tourist.Tip.Base
	_module: 'Tourist'
	_.extend @prototype, Backbone.Events

	visable: false

	# You can override any of thsee templates for your own stuff
	skipButtonTemplate: '<button class="btn btn-default btn-sm pull-right tour-next">Skip this step →</button>'
	nextButtonTemplate: '<button class="btn btn-primary btn-sm pull-right tour-next">Next step →</button>'
	finalButtonTemplate: '<button class="btn btn-primary btn-sm pull-right tour-next">Finish up</button>'

	closeButtonTemplate: '<a class="btn btn-close tour-close" href="#"><i class="<%= classes %>"></i></a>'
	okButtonTemplate: '<button class="btn btn-sm tour-close btn-primary">Okay</button>'
	coverTemplate: '<div class="<%= classes %>" tabindex="1"></div>'

	actionLabelTemplate: _.template '<h4 class="action-label"><%= label %></h4>'
	actionLabels: ['Do this:', 'Then this:', 'Next this:']

	highlightClass: 'tour-highlight'
	closeButtonClasses: 'icon icon-remove'
	touristCoverClasses: 'tourist-cover'

	addedHightlightClasses: undefined

	template: _.template '''
		<div>
			<div class="tour-container">
				<%= close_button %>
				<%= content %>
				<p class="tour-counter <%= counter_class %>"><%= counter%></p>
			</div>
			<div class="tour-buttons">
				<%= buttons %>
			</div>
		</div>
	'''

	# options -
	#   model - a Tourist.Model object
	constructor: (@options={}) ->
		@el = $('<div/>')

		@initialize(options)

		@cover = $.parseHTML(@coverTemplate)

		@_bindClickEvents()

		Tourist.Tip.Base._cacheTip(this)

	destroy: ->
		@el.remove()
		@cover.remove() if @cover? and @cover.remove?
		
		false

	# Render the current step as specified by the Tour Model
	#
	# step - step object
	#
	# Return this
	render: (step) ->
		@hide()

		if step
			@_setTarget(step.target or false, step)
			@_setZIndex('')
			@_renderContent(step, @_buildContentElement(step))
			@show() if step.target
			@_setZIndex(step.zIndex, step) if step.zIndex

			cover = @_buildCover(step)
			$('body').append(cover) if step.cover?

			@visible = true

		this

	# Show the tip
	show: ->
		@cover.show().addClass('visible') if @cover?
		# Override me

	# Hide the tip
	hide: ->
		@cover.hide().removeClass('visible') if @cover?
		@visable = false
		# Override me

	# Set the element which the tip will point to
	#
	# targetElement - a jquery element
	# step - step object
	setTarget: (targetElement, step) ->
		@_setTarget(targetElement, step)

	# Unhighlight and unset the current target
	cleanupCurrentTarget: ->
		if @target? and @target.removeClass?
			@target.removeClass(@highlightClass)

			if @addedHightlightClasses?
				@target.removeClass(@addedHightlightClasses) 
				@addedHightlightClasses = undefined

		if @cover? 
			$('.tourist-cover').remove()

		@target = null

	###
	Event Handlers
	###

	# User clicked close or ok button
	onClickClose: (event) =>
		@trigger('click:close', this, event)
		false

	# User clicked next or skip button
	onClickNext: (event) =>
		@trigger('click:next', this, event)
		false


	###
	Private
	###

	# Returns the jquery element that contains all the tip data.
	_getTipElement: ->
		# Override me

	# Place content into your tip's body. Called in render()
	#
	# step - the step object for the current step
	# contentElement - a jquery element containing all the tip's content
	#
	# Returns nothing
	_renderContent: (step, contentElement) ->
		# Override me

	# Bind to the buttons
	_bindClickEvents: ->
		el = @_getTipElement()
		el.delegate('.tour-close', 'click', @onClickClose)
		el.delegate('.tour-next', 'click', @onClickNext)


		that = @

		cont = $('body')

		cont.keyup (e) ->

			visable = el.is(":visible"); 

			key = e.which

			if e.target.nodeName != 'INPUT' and e.target.nodeName != 'TEXTAREA'

				if visable
					if key == 39 # Right 
						that.onClickNext()
					else if key == 27 # esc
						that.onClickClose()

					if key == 39 or key == 27 
						e.preventDefault()

			false

	# Set the current target
	#
	# target - a jquery element that this flyout should point to.
	# step - step object
	#
	# Return nothing
	_setTarget: (target, step) ->
		@cleanupCurrentTarget()

		if target and step and step.highlightTarget
			target.addClass(@highlightClass)
			
			if step.highlightClass?

				@addedHightlightClasses = step.highlightClass

				target.addClass(step.highlightClass)

		@target = target

	# Set z-index on the tip element.
	#
	# zIndex - the z-index desired; falsy val will clear it.
	_setZIndex: (zIndex) ->
		el = @_getTipElement()
		el.css('z-index', zIndex or '')

	# Will build the element that has all the content for the current step
	#
	# step - the step object for the current step
	#
	# Returns a jquery object with all the content.
	_buildContentElement: (step) ->
		buttons = @_buildButtons(step)

		content = $($.parseHTML(@template(
			content: step.content
			buttons: buttons
			close_button: @_buildCloseButton(step)
			counter: if step.final then '' else "step #{step.index+1} of #{step.total}"
			counter_class: if step.final then 'final' else ''
		)))
		content.find('.tour-buttons').addClass('no-buttons') unless buttons

		@_renderActionLabels(content)

		content

	# Create buttons based on step options.
	#
	# Returns a string of button html to be placed into the template.
	_buildButtons: (step) ->
		buttons = ''

		buttons += @okButtonTemplate if step.okButton
		buttons += @skipButtonTemplate if step.skipButton

		if step.nextButton
			buttons += if step.final then @finalButtonTemplate else @nextButtonTemplate

		buttons

	_buildCloseButton: (step) ->

		closeButton = @closeButtonTemplate

		closeClass = @closeButtonClasses

		closeClass += ' ' + step.closeButtonClass if step.closeButtonClass

		closeButton = closeButton.replace /<%= classes %>/, closeClass

		if step.closeButton then closeButton else ''

	_buildCover: (step) ->

		coverDiv = @coverTemplate

		coverClass = @touristCoverClasses

		coverClass += ' ' + step.coverClass if step.coverClass

		coverDiv = coverDiv.replace /<%= classes %>/, coverClass

		if step.cover then coverDiv else ''


	_renderActionLabels: (el) ->
		actions = el.find('.action')
		actionIndex = 0
		for action in actions
			label = $($.parseHTML(@actionLabelTemplate(label: @actionLabels[actionIndex])))
			label.insertBefore(action)
			actionIndex++

	# Caches this tip for destroying it later.
	@_cacheTip: (tip) ->
		Tourist.Tip.Base._cachedTips = [] unless Tourist.Tip.Base._cachedTips
		Tourist.Tip.Base._cachedTips.push(tip)

	# Destroy all tips. Useful in tests.
	@destroy: ->
		return unless Tourist.Tip.Base._cachedTips
		for tip in Tourist.Tip.Base._cachedTips
			tip.destroy()
		Tourist.Tip.Base._cachedTips = null
