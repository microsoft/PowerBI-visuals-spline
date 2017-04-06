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
module powerbi.extensibility.visual.PBI_CV_9D783E0D_2610_4C22_9576_88AD092AB59E  {

    // in order to improve the performance, one can update the <head> only in the initial rendering.
    // set to 'true' if you are using different packages to create the widgets
    const updateHTMLHead: boolean = false;
    const renderVisualUpdateType: number[] = [VisualUpdateType.Resize, VisualUpdateType.ResizeEnd, VisualUpdateType.Resize + VisualUpdateType.ResizeEnd];


    interface VisualSettingsSplineParams {
        smoothness: number;
        lineColor: string;
    }

    interface VisualSettingsConfParams {
        show: boolean;
        confLevel: number;
    }

    interface VisualSettingsScatterParams {
        pointColor: string;
        weight: number;
        percentile: number;
    }

    export class Visual implements IVisual {
        //    private imageDiv: HTMLDivElement;
        //   private imageElement: HTMLImageElement;
        //HTML
        private rootElement: HTMLElement;
        private headNodes: Node[];
        private bodyNodes: Node[];

        private settings_spline: VisualSettingsSplineParams;
        private settings_conf: VisualSettingsConfParams;
        private settings_scatter: VisualSettingsScatterParams;

        public constructor(options: VisualConstructorOptions) {
            if(options && options.element)
                this.rootElement = options.element;

            this.headNodes = [];
            this.bodyNodes = [];

            // default parameters
            this.settings_spline = <VisualSettingsSplineParams>{
                smoothness: 30,
                lineColor: "red"
            };
            this.settings_scatter = <VisualSettingsScatterParams>{
                pointColor: "blue",
                weight: 10, 
                percentile: 40
            };
            this.settings_conf = <VisualSettingsConfParams>{
                show: true,
                confLevel: 0.99
            };
        }

        public update(options: VisualUpdateOptions) {
            if (!options || !options.type || !options.viewport)
                return;

            let dataViews: DataView[] = options.dataViews;
            if (!dataViews || dataViews.length === 0)
                return;

            let dataView: DataView = dataViews[0];
            if (!dataView || !dataView.metadata)
                return;

            this.updateObjects(dataView.metadata.objects);

            let payloadBase64: string = null;
            if (dataView.scriptResult && dataView.scriptResult.payloadBase64) {
                payloadBase64 = dataView.scriptResult.payloadBase64;
            }

            if (renderVisualUpdateType.indexOf(options.type) === -1) {
                if (payloadBase64) {
                    this.injectCodeFromPayload(payloadBase64);
                }
            }
            
            this.onResizing(options.viewport);
        }

        public onResizing(finalViewport: IViewport): void {
            /* add code to handle resizing of the view port */
        }

      private injectCodeFromPayload(payloadBase64: string): void {
            // Inject HTML from payload, created in R
            // the code is injected to the 'head' and 'body' sections.
            // if the visual was already rendered, the previous DOM elements are cleared

            ResetInjector();

            if (!payloadBase64) 
                return

            // create 'virtual' HTML, so parsing is easier
            let el: HTMLHtmlElement = document.createElement('html');
            try {
                el.innerHTML = window.atob(payloadBase64);
            } catch (err) {
                return;
            }

            // if 'updateHTMLHead == false', then the code updates the header data only on the 1st rendering
            // this option allows loading and parsing of large and recurring scripts only once.
            if (updateHTMLHead || this.headNodes.length === 0) {
                while (this.headNodes.length > 0) {
                    let tempNode: Node = this.headNodes.pop();
                    document.head.removeChild(tempNode);
                }
                let headList: NodeListOf<HTMLHeadElement> = el.getElementsByTagName('head');
                if (headList && headList.length > 0) {
                    let head: HTMLHeadElement = headList[0];
                    this.headNodes = ParseElement(head, document.head);
                }
            }

            // update 'body' nodes, under the rootElement
            while (this.bodyNodes.length > 0) {
                let tempNode: Node = this.bodyNodes.pop();
                this.rootElement.removeChild(tempNode);
            }
            let bodyList: NodeListOf<HTMLBodyElement> = el.getElementsByTagName('body');
            if (bodyList && bodyList.length > 0) {
                let body: HTMLBodyElement = bodyList[0];
                this.bodyNodes = ParseElement(body, this.rootElement);
            }

            RunHTMLWidgetRenderer();
        }


        /**
         * This function gets called by the update function above. You should read the new values of the properties into 
         * your settings object so you can use the new value in the enumerateObjectInstances function below.
         * 
         * Below is a code snippet demonstrating how to expose a single property called "lineColor" from the object called "settings"
         * This object and property should be first defined in the capabilities.json file in the objects section.
         * In this code we get the property value from the objects (and have a default value in case the property is undefined)
         */
        public updateObjects(objects: DataViewObjects) {
            /*this.settings = <VisualSettings>{
                lineColor: getFillValue(object, 'settings', 'lineColor', "#333333")
            };*/
             this.settings_spline = <VisualSettingsSplineParams> {
                smoothness: getValue<number>(objects, 'settings_spline_params', 'percentile', 30),                
                lineColor: getValue<string>(objects, 'settings_spline_params', 'lineColor', 'red'),
            };

            this.settings_scatter = <VisualSettingsScatterParams> {
                pointColor: getValue<string>(objects, 'settings_scatter_params', 'pointColor', 'blue'),
                weight: getValue<number>(objects, 'settings_scatter_params', 'weight', 10),
                percentile: getValue<number>(objects, 'settings_scatter_params', 'percentile', 40),
            };

            this.settings_conf = <VisualSettingsConfParams> {
                confLevel: getValue<number>(objects, 'settings_conf_params', 'confLevel', 0.99),                
                show: getValue<boolean>(objects, 'settings_conf_params', 'show', true),
            };
        }
        
        public enumerateObjectInstances(options: EnumerateVisualObjectInstancesOptions): VisualObjectInstanceEnumeration {
            let objectName = options.objectName;
            let objectEnumeration = [];

            switch (objectName) {
                case 'settings_spline_params':
                    objectEnumeration.push({
                        objectName: objectName,
                        properties: {
                            percentile: inMinMax(this.settings_spline.smoothness,1,100),
                            lineColor: this.settings_spline.lineColor
                        },
                        selector: null
                    });
                    break;
                case 'settings_conf_params':
                    objectEnumeration.push({
                        objectName: objectName,
                        properties: {
                            confLevel: inMinMax(this.settings_conf.confLevel,0.25,1),
                            show: this.settings_conf.show
                        },
                        selector: null
                    });
                    break;
                case 'settings_scatter_params':
                    objectEnumeration.push({
                        objectName: objectName,
                        properties: {
                            pointColor: this.settings_scatter.pointColor,
                            weight: inMinMax(this.settings_scatter.weight,1,50), 
                            percentile: this.settings_scatter.percentile
                        },
                        selector: null
                    });
                    break;
            };

            return objectEnumeration;
        }
    }
}