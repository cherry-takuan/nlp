# メモ  
PC側はタイムアウト設定必須  
リングバス接続断を検出したい  
## 目指す入出力
### 構成  

・スレーブ2台  
・スレーブ1 16bit全出力  
・スレーブ2 16bit全入力  

```
    ┌───┐  ┌────┐  ┌────┐  
PC⇔│master│→│スレーブ│→│スレーブ│─┐  
    │      │←│ID 0    │←│ID 1    │─┘  
    └───┘  └────┘  └────┘  
                      ↓            ↓  
                     NLP-16Aの対象I/Oへ  
```

### 初期化フェーズ

マスタ出力  
FE-00-0000  
スレーブ出力  
FE-00-0002  
0002が返ってきているためスレーブ台数は2台と推定できる．  

### 機器状態取得
未定  

### 入出力方向取得フェーズ
#### スレーブ1
マスタ出力  
00-01-0000  
スレーブ出力  
FF-01-XXXX  

#### スレーブ2
マスタ出力  
01-01-0000  
スレーブ出力  
FF-01-XXXX  
