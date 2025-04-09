import { router } from '@kit.ArkUI';
import { connection } from '@kit.ConnectivityKit';
import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { buffer } from '@kit.ArkTS';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct Main{
  @State state: string = "离线"
  @State color:Color = Color.Red
  @State light_color:Color = Color.Gray
  address:string = ""
  client_num = -1

  strToBuffer(src: string, encoding: buffer.BufferEncoding = 'utf-8'): ArrayBuffer {
    let buf = buffer.from(src, encoding);
    return buf.buffer
  }

  getDevice = (): boolean=>{
    try{
      let devices: Array<string> = connection.getPairedDevices()
      for(let i=0; i<devices.length; i++){
        if(connection.getRemoteDeviceName(devices[i])=="ESP32_Server"){
          this.address = devices[i]
          return true
        }
      }
    } catch (err) {
      console.error("errCode:" + err.code + ",errMessage:" + err.message)
    }
    return false
  }

  scanAndPair = ()=>{
    try {
      connection.on('bluetoothDeviceFind', (data)=>{
        for(let i=0;i<data.length;i++){
          let adrr = data[i]
          if(adrr!=""){
            let name = connection.getRemoteDeviceName(adrr)
            if(name == "ESP32_Server"){
              connection.pairDevice(adrr)
            }
          }
        }
      });
      connection.startBluetoothDiscovery();
    } catch (err) {
      console.error("errCode:" + err.code + ",errMessage:" + err.message);
    }
  }

  connect = ()=>{
    try{
      socket.sppConnect(this.address, {uuid: '00001101-0000-1000-8000-00805f9b34fb', secure: false, type: 0},
        (code: BusinessError, number: number)=>{
          if (code) {
            console.error('sppListen error, code is ' + code)
            promptAction.showToast({message: '连接失败', duration: 2000})
            return;
          }
          this.client_num = number
          promptAction.showToast({message: '连接成功', duration: 2000})
          this.state = "在线"
          this.color = Color.Green
          // this.sendCmd()
        })
    } catch (err) {
      console.error("errCode:" + err.code + ",errMessage:" + err.message);
      promptAction.showToast({message: '连接失败', duration: 2000})
    }
  }

  sendCmd = ()=>{
    try{
      socket.sppWrite(this.client_num, this.strToBuffer("switch"))
      this.light_color==Color.Gray ? this.light_color = Color.Green : this.light_color = Color.Gray
      socket.sppCloseClientSocket(this.client_num)
    } catch (err) {
      console.error("errCode:" + err.code + ",errMessage:" + err.message);
      if(err.code == 2901054){
        promptAction.showToast({message: '连接已丢失请重试', duration: 2000})
        this.client_num = -1
        this.state = "离线"
        this.color = Color.Red
      }
    }
  }

  build() {
    RelativeContainer(){
      Button("debug")
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top }
        })
        .onClick(()=>{
          router.pushUrl({url: "pages/Test"})
        })

      Text(this.state)
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          right: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .fontColor(this.color)
        .margin({right: 20, top: 15})

      Button({type: ButtonType.Circle})
        .width(200)
        .backgroundColor(this.light_color)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(()=>{
          if(!this.getDevice()){
            this.scanAndPair()
            return
          }
          this.connect()
          this.sendCmd()
        })
    }
  }
}