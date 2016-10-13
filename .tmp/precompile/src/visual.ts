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
module powerbi.extensibility.visual.PBI_CV_3DFBB0D1_6AFB_4242_B6E1_7116023B1167  {

    interface VisualSettingsSplineParams {
        smoothness: number;
        lineColor: string;
    }

    interface VisualSettingsConfParams {
        showConf: boolean;
        confLevel:number;
    }

    interface VisualSettingsScatterParams {
        pointColor: string;
    }
    
    export class Visual implements IVisual {
        private imageDiv: HTMLDivElement;
        private imageElement: HTMLImageElement;
        
        private settings_spline: VisualSettingsSplineParams;
        private settings_conf: VisualSettingsConfParams;
        private settings_scatter: VisualSettingsScatterParams;

        public constructor(options: VisualConstructorOptions) {
            this.imageDiv = document.createElement('div');
            this.imageDiv.className = 'rcv_autoScaleImageContainer';
            options.element.appendChild(this.imageDiv);
            
            this.imageElement = document.createElement('img');
            this.imageElement.className = 'rcv_autoScaleImage';

            this.imageDiv.appendChild(this.imageElement);

            this.settings_spline = <VisualSettingsSplineParams>{
                smoothness: 30,
                lineColor: "red"
            };
            this.settings_scatter = <VisualSettingsScatterParams>{
                pointColor: "blue"
            };
            this.settings_conf = <VisualSettingsConfParams>{
                showConf: true,
                confLevel: 0.99
            };
        }

        public update(options: VisualUpdateOptions) {
            let dataViews: DataView[] = options.dataViews;
            if (!dataViews || dataViews.length === 0)
                return;

            let dataView: DataView = dataViews[0];
            if (!dataView || !dataView.metadata)
                return;

            this.settings_spline = <VisualSettingsSplineParams> {
                smoothness: getValue<number>(dataView.metadata.objects, 'settings_spline_params', 'percentile', 30),                
                lineColor: getValue<string>(dataView.metadata.objects, 'settings_spline_params', 'lineColor', 'red'),
            };

            this.settings_scatter = <VisualSettingsScatterParams> {
                pointColor: getValue<string>(dataView.metadata.objects, 'settings_scatter_params', 'pointColor', 'blue'),
            };

            this.settings_conf = <VisualSettingsConfParams> {
                confLevel: getValue<number>(dataView.metadata.objects, 'settings_conf_params', 'confLevel', 0.99),                
                showConf: getValue<boolean>(dataView.metadata.objects, 'settings_conf_params', 'showConf', true),
            };

            let imageUrl: string = null;
            if (dataView.scriptResult && dataView.scriptResult.payloadBase64) {
                imageUrl = "data:image/png;base64," + dataView.scriptResult.payloadBase64;
            }

            if (imageUrl) {
                this.imageElement.src = imageUrl;
            } else {
                this.imageElement.src = null;
            }

            this.onResizing(options.viewport);
        }

        public onResizing(finalViewport: IViewport): void {
            this.imageDiv.style.height = finalViewport.height + 'px';
            this.imageDiv.style.width = finalViewport.width + 'px';
        }

        public enumerateObjectInstances(options: EnumerateVisualObjectInstancesOptions): VisualObjectInstanceEnumeration {
            let objectName = options.objectName;
            let objectEnumeration = [];

            switch(objectName) {
                case 'settings_spline_params':
                    objectEnumeration.push({
                        objectName: objectName,
                        properties: {
                            percentile: this.settings_spline.smoothness,
                            lineColor: this.settings_spline.lineColor
                         },
                        selector: null
                    });
                    break;
                case 'settings_conf_params':
                    objectEnumeration.push({
                        objectName: objectName,
                        properties: {
                            confLevel: this.settings_conf.confLevel,
                            showConf: this.settings_conf.showConf
                         },
                        selector: null
                    });
                    break;
                case 'settings_scatter_params':
                    objectEnumeration.push({
                        objectName: objectName,
                        properties: {
                            pointColor: this.settings_scatter.pointColor
                         },
                        selector: null
                    });
                    break;
            };

            return objectEnumeration;
        }
    }
}