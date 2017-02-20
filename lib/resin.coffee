###
Copyright 2016 Resin.io

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###

assign = require('lodash/assign')
mapValues = require('lodash/mapValues')
defaults = require('lodash/defaults')
getRequest = require('resin-request')
getToken = require('resin-token')
getPine = require('resin-pine')
{ notImplemented } = require('./util')

###*
# @namespace resin
# @description
# Welcome to the Resin SDK documentation.
#
# This document aims to describe all the functions supported by the SDK, as well as showing examples of their expected usage.
#
# If you feel something is missing, not clear or could be improved, please don't hesitate to open an [issue in GitHub](https://github.com/resin-io/resin-sdk/issues/new), we'll be happy to help.
###
sdkTemplate =

	###*
	# @namespace models
	# @memberof resin
	###
	models: require('./models')

	###*
	# @namespace auth
	# @memberof resin
	###
	auth: require('./auth')

	###*
	# @namespace logs
	# @memberof resin
	###
	logs: require('./logs')

	###*
	# @namespace settings
	# @memberof resin
	###
	settings: require('./settings')

module.exports = getSdk = (opts = {}) ->
	defaults opts,
		apiUrl: 'https://api.resin.io/'
		apiVersion: 'v2'
		isBrowser: window?

	if opts.isBrowser
		settings =
			get: notImplemented
			getAll: notImplemented
	else
		settings = require('resin-settings-client')
		defaults opts,
			imageMakerUrl: settings.get('imageMakerUrl')
			dataDirectory: settings.get('dataDirectory')

	token = getToken(opts)
	request = getRequest(assign({}, opts, { token }))
	pine = getPine(assign({}, opts, { token, request }))

	deps = {
		settings
		request
		token
		pine
	}

	sdk = mapValues(sdkTemplate, (moduleFactory) -> moduleFactory(deps, opts))

	###*
	# @typedef Interceptor
	# @type {object}
	# @memberof resin.interceptors
	#
	# @description
	# An interceptor implements some set of the four interception hook callbacks.
	# To continue processing, each function should return a value or a promise that
	# successfully resolves to a value.
	#
	# To halt processing, each function should throw an error or return a promise that
	# rejects with an error.
	#
	# @property {function} [request] - Callback invoked before requests are made. Called with
	# the request options, should return (or resolve to) new request options, or throw/reject.
	#
	# @property {function} [response] - Callback invoked before responses are returned. Called with
	# the response, should return (or resolve to) a new response, or throw/reject.
	#
	# @property {function} [requestError] - Callback invoked if an error happens before a request.
	# Called with the error itself, caused by a preceeding request interceptor rejecting/throwing
	# an error for the request, or a failing in preflight token validation. Should return (or resolve
	# to) new request options, or throw/reject.
	#
	# @property {function} [responseError] - Callback invoked if an error happens in the response.
	# Called with the error itself, caused by a preceeding response interceptor rejecting/throwing
	# an error for the request, a network error, or an error response from the server. Should return
	# (or resolve to) a new response, or throw/reject.
	###


	###*
	# @summary Array of interceptors
	# @member {Interceptor[]} interceptors
	# @public
	# @memberof resin
	#
	# @description
	# The current array of interceptors to use. Interceptors intercept requests made
	# internally and are executed in the order they appear in this array for requests,
	# and in the reverse order for responses.
	#
	# @example
	# resin.interceptors.push({
	#	responseError: function (error) {
	#		console.log(error);
	#		throw error;
	#	})
	# });
	###
	Object.defineProperty sdk, 'interceptors',
		get: -> request.interceptors,
		set: (interceptors) -> request.interceptors = interceptors

	return sdk
