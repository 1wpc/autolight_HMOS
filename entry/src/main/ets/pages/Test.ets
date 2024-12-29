import { abilityAccessCtrl, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.ConnectivityKit';
import { socket } from '@kit.ConnectivityKit';
import { buffer } from '@kit.ArkTS';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  devices: Array<string> = []
  address = ""
  client_num = -1

  strToBuffer(src: string, encoding: buffer.BufferEncoding = 'utf-8'): ArrayBuffer {
    let buf = buffer.from(src, encoding);
    return buf.buffer
  }

  async _requestPermission(): Promise<boolean> {
    return new Promise((r, j) => {
      // 此处 permissionList 需要在项目的 module.json5 文件中添加权限与描述
      let permissionList: Permissions[] = ["ohos.permission.ACCESS_BLUETOOTH","ohos.permission.APPROXIMATELY_LOCATION","ohos.permission.LOCATION","ohos.permission.DISCOVER_BLUETOOTH"]
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      atManager.requestPermissionsFromUser(getContext(), permissionList,
        (err: BusinessError, data: PermissionRequestResult) => {
          if (err) {
            console.error(`luvi > requestPermissionsFromUser fail, err->${JSON.stringify(err)}`);
            r(false)
          } else {
            console.info('luvi > data:' + JSON.stringify(data));
            console.info('luvi > data permissions:' + data.permissions);
            console.info('luvi > data authResults:' + data.authResults);
            console.info('luvi > data dialogShownResults:' + data.dialogShownResults);
            // 授权成功
            data.authResults?.forEach((aItem) => {
              aItem == 0 && r(true)
            })
          }
        });
    })
  }

  getDevice(){
    try {
      let devices: Array<string> = connection.getPairedDevices()
      devices.forEach((value)=>{
        if(connection.getRemoteDeviceName(value)=="ESP32_Server") return
      })

      connection.on('bluetoothDeviceFind', (data)=>{
        for(let i=0;i<data.length;i++){
          let adrr = data[i]
          console.log("BLE scan result:"+adrr)
          if(adrr!=""){
            let name = connection.getRemoteDeviceName(adrr)
            if(name!=""&&!this.devices.includes(name))this.devices.push(name)
            if(name == "ESP32_Server"){
              connection.pairDevice(adrr)
              this.address = adrr
            }
          }
        }
        this.message = this.devices.join(",")
      });
      connection.startBluetoothDiscovery();
    } catch (err) {
      console.error("errCode:" + err.code + ",errMessage:" + err.message);
    }
  }

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })

      Button("扫描并配对")
        .id('but1')
        .alignRules({
          bottom: { anchor: 'HelloWorld', align: VerticalAlign.Top }
        })
        .onClick(()=>{
          this.message = "test"
          this._requestPermission();
          this.getDevice();
        })

      Button("connect")
        .id("but2")
        .alignRules({
          left: { anchor: 'but1', align: HorizontalAlign.End }
        })
        .onClick(()=>{
          socket.sppConnect(this.address, {uuid: '00001101-0000-1000-8000-00805f9b34fb', secure: false, type: 0},
            (code: BusinessError, number: number)=>{
              this.client_num = number
            })
        })

      Button("send")
        .alignRules({
          left: { anchor: 'but2', align: HorizontalAlign.End }
        })
        .onClick(()=>{
          socket.sppWrite(this.client_num, this.strToBuffer("hello"))
        })
    }
    .height('100%')
    .width('100%')
  }
}