var powerbi;
(function (powerbi) {
    var extensibility;
    (function (extensibility) {
        var visual;
        (function (visual) {
            var PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167;
            (function (PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167) {
                /**
                 * Gets property value for a particular object.
                 *
                 * @function
                 * @param {DataViewObjects} objects - Map of defined objects.
                 * @param {string} objectName       - Name of desired object.
                 * @param {string} propertyName     - Name of desired property.
                 * @param {T} defaultValue          - Default value of desired property.
                 */
                function getValue(objects, objectName, propertyName, defaultValue) {
                    if (objects) {
                        var object = objects[objectName];
                        if (object) {
                            var property = object[propertyName];
                            if (property !== undefined) {
                                return property;
                            }
                        }
                    }
                    return defaultValue;
                }
                PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.getValue = getValue;
                /**
                 * Gets property value for a particular object in a category.
                 *
                 * @function
                 * @param {DataViewCategoryColumn} category - List of category objects.
                 * @param {number} index                    - Index of category object.
                 * @param {string} objectName               - Name of desired object.
                 * @param {string} propertyName             - Name of desired property.
                 * @param {T} defaultValue                  - Default value of desired property.
                 */
                function getCategoricalObjectValue(category, index, objectName, propertyName, defaultValue) {
                    var categoryObjects = category.objects;
                    if (categoryObjects) {
                        var categoryObject = categoryObjects[index];
                        if (categoryObject) {
                            var object = categoryObject[objectName];
                            if (object) {
                                var property = object[propertyName];
                                if (property !== undefined) {
                                    return property;
                                }
                            }
                        }
                    }
                    return defaultValue;
                }
                PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.getCategoricalObjectValue = getCategoricalObjectValue;
            })(PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167 = visual.PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167 || (visual.PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167 = {}));
        })(visual = extensibility.visual || (extensibility.visual = {}));
    })(extensibility = powerbi.extensibility || (powerbi.extensibility = {}));
})(powerbi || (powerbi = {}));
/*
 *  Power BI Visual CLI
 *
 *  Copyright (c) Microsoft Corporation
 *  All rights reserved.
 *  MIT License
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the ""Software""), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */
var powerbi;
(function (powerbi) {
    var extensibility;
    (function (extensibility) {
        var visual;
        (function (visual) {
            var PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167;
            (function (PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167) {
                var Visual = (function () {
                    function Visual(options) {
                        this.imageDiv = document.createElement('div');
                        this.imageDiv.className = 'rcv_autoScaleImageContainer';
                        options.element.appendChild(this.imageDiv);
                        this.imageElement = document.createElement('img');
                        this.imageElement.className = 'rcv_autoScaleImage';
                        this.imageDiv.appendChild(this.imageElement);
                        this.settings_spline = {
                            smoothness: 30,
                            lineColor: "red"
                        };
                        this.settings_scatter = {
                            pointColor: "blue"
                        };
                        this.settings_conf = {
                            showConf: true,
                            confLevel: 0.99
                        };
                    }
                    Visual.prototype.update = function (options) {
                        var dataViews = options.dataViews;
                        if (!dataViews || dataViews.length === 0)
                            return;
                        var dataView = dataViews[0];
                        if (!dataView || !dataView.metadata)
                            return;
                        this.settings_spline = {
                            smoothness: PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.getValue(dataView.metadata.objects, 'spline_settings', 'percentile', 30),
                            lineColor: PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.getValue(dataView.metadata.objects, 'spline_settings', 'lineColor', 'red'),
                        };
                        this.settings_scatter = {
                            pointColor: PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.getValue(dataView.metadata.objects, 'scatter_settings', 'pointColor', 'blue'),
                        };
                        this.settings_conf = {
                            confLevel: PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.getValue(dataView.metadata.objects, 'conf_settings', 'confLevel', 0.99),
                            showConf: PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.getValue(dataView.metadata.objects, 'conf_settings', 'showConf', true),
                        };
                        var imageUrl = null;
                        if (dataView.scriptResult && dataView.scriptResult.payloadBase64) {
                            imageUrl = "data:image/png;base64," + dataView.scriptResult.payloadBase64;
                        }
                        if (imageUrl) {
                            this.imageElement.src = imageUrl;
                        }
                        else {
                            this.imageElement.src = null;
                        }
                        this.onResizing(options.viewport);
                    };
                    Visual.prototype.onResizing = function (finalViewport) {
                        this.imageDiv.style.height = finalViewport.height + 'px';
                        this.imageDiv.style.width = finalViewport.width + 'px';
                    };
                    Visual.prototype.enumerateObjectInstances = function (options) {
                        var objectName = options.objectName;
                        var objectEnumeration = [];
                        switch (objectName) {
                            case 'spline_settings':
                                objectEnumeration.push({
                                    objectName: objectName,
                                    properties: {
                                        percentile: this.settings_spline.smoothness,
                                        lineColor: this.settings_spline.lineColor
                                    },
                                    selector: null
                                });
                                break;
                            case 'conf_settings':
                                objectEnumeration.push({
                                    objectName: objectName,
                                    properties: {
                                        confLevel: this.settings_conf.confLevel,
                                        showConf: this.settings_conf.showConf
                                    },
                                    selector: null
                                });
                                break;
                            case 'scatter_settings':
                                objectEnumeration.push({
                                    objectName: objectName,
                                    properties: {
                                        pointColor: this.settings_scatter.pointColor
                                    },
                                    selector: null
                                });
                                break;
                        }
                        ;
                        return objectEnumeration;
                    };
                    return Visual;
                }());
                PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.Visual = Visual;
            })(PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167 = visual.PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167 || (visual.PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167 = {}));
        })(visual = extensibility.visual || (extensibility.visual = {}));
    })(extensibility = powerbi.extensibility || (powerbi.extensibility = {}));
})(powerbi || (powerbi = {}));
var powerbi;
(function (powerbi) {
    var visuals;
    (function (visuals) {
        var plugins;
        (function (plugins) {
            plugins.PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167 = {
                name: 'PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167',
                displayName: 'spline',
                class: 'Visual',
                version: '1.0.0',
                apiVersion: '1.2.0',
                create: function (options) { return new powerbi.extensibility.visual.PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167.Visual(options); },
                custom: true
            };
        })(plugins = visuals.plugins || (visuals.plugins = {}));
    })(visuals = powerbi.visuals || (powerbi.visuals = {}));
})(powerbi || (powerbi = {}));
//# sourceMappingURL=visual.js.map