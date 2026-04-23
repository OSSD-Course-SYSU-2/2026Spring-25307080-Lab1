// 定义接口
interface LevelConfig {
  time: number;
  speed: number;
  maxScore: number;
}

interface Hammer {
  id: number;
  name: string;
  icon: string;
  color: ResourceColor;
  scoreMultiplier: number; // 分数加成
}

@Entry
@Component
struct Index {
  // 页面状态
  @State currentPage: string = "login";
  @State username: string = "";
  @State selectedHammer: Hammer = { id: 1, name: "木锤", icon: "🔨", color: "#8D6E63", scoreMultiplier: 1.0 };

  // 游戏数据
  @State score: number = 0;
  @State level: number = 1;
  @State timeLeft: number = 30;
  @State gameStart: boolean = false;
  @State gameOver: boolean = false;
  @State levelFailed: boolean = false;
  @State moleVisible: boolean[] = [false, false, false, false, false, false, false, false, false];
  @State moleInterval: number = 0;
  @State timerInterval: number = 0;
  @State countdownNum: number = 3;
  // 新增状态：连击、暂停
  @State comboCount: number = 0;
  @State isPaused: boolean = false;

  // 锤子列表
  hammerList: Hammer[] = [
    { id: 1, name: "木锤", icon: "🔨", color: "#8D6E63", scoreMultiplier: 1.0 },
    { id: 2, name: "金锤", icon: "⚒️", color: "#FFD700", scoreMultiplier: 1.5 },
    { id: 3, name: "雷神锤", icon: "🛠️", color: "#4A90E2", scoreMultiplier: 2.0 }
  ];

  // 关卡配置（三关 + 每关总分）
  levelConfig: LevelConfig[] = [
    { time: 30, speed: 1000, maxScore: 300 },  // 关1
    { time: 30, speed: 800, maxScore: 350 },  // 关2
    { time: 30, speed: 550, maxScore: 400 }   // 关3
  ];

  build() {
    Column() {
      if (this.currentPage === "login") {
        this.loginPage();
      } else if (this.currentPage === "selectHammer") {
        this.hammerSelectPage();
      } else if (this.currentPage === "countdown") {
        this.countdownPage();
      } else if (this.currentPage === "game") {
        this.gamePage();
      } else if (this.currentPage === "result") {
        this.resultPage();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF3E0');
  }

  // 登录页
  @Builder
  loginPage() {
    Column() {
      Text("打地鼠游戏")
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E65100')
        .margin({ top: 120, bottom: 60 });

      TextInput({ placeholder: "请输入用户名" })
        .width('80%')
        .height(50)
        .fontSize(18)
        .margin({ bottom: 30 })
        .onChange((val: string) => {
          this.username = val;
        });

      Button("进入游戏")
        .width('80%')
        .height(55)
        .fontSize(22)
        .backgroundColor('#FF9800')
        .borderRadius(12)
        .margin({ bottom: 20 })
        .onClick(() => {
          if (this.username.trim() !== "") {
            this.currentPage = "selectHammer";
          }
        });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }

  // 锤子选择页
  @Builder
  hammerSelectPage() {
    Column() {
      Text("选择你的锤子")
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 40 });

      Grid() {
        ForEach(this.hammerList, (hammer: Hammer) => {
          GridItem() {
            Column() {
              Text(hammer.icon)
                .fontSize(60);
              Text(hammer.name)
                .fontSize(20)
                .margin({ top: 10 });
              Text(`倍率 x${hammer.scoreMultiplier}`)
                .fontSize(14)
                .fontColor('#666');
            }
            .width('90%')
            .height(180)
            .backgroundColor(this.selectedHammer.id === hammer.id ? '#FFE0B2' : '#FFFFFF')
            .borderRadius(16)
            .border({ width: 3, color: this.selectedHammer.id === hammer.id ? '#FF9800' : '#EEEEEE' })
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.selectedHammer = hammer;
            });
          }
        });
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr')
      .width('90%')
      .height(200)
      .margin({ bottom: 50 });

      Button("开始游戏")
        .width('80%')
        .height(55)
        .fontSize(22)
        .backgroundColor('#4CAF50')
        .borderRadius(12)
        .onClick(() => {
          this.currentPage = "countdown";
          this.startCountdown();
        });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }

  // 倒计时页
  @Builder
  countdownPage() {
    Column() {
      Text(this.countdownNum.toString())
        .fontSize(120)
        .fontWeight(FontWeight.Bold)
        .fontColor('#E53935')
        .animation({ duration: 800, curve: Curve.EaseOut });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  // 游戏页（新增底部功能栏）
  @Builder
  gamePage() {
    Column() {
      // 顶部信息栏
      Row() {
        Text(`玩家: ${this.username}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold);
        Text(`关卡: ${this.level}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20 });
        Text(`分数: ${this.score}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20 });
        Text(`时间: ${this.timeLeft}s`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20 });
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(15)
      .backgroundColor('#FFF8E1')
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16 });

      // 地鼠洞区域（上半部分）
      Grid() {
        ForEach(this.moleVisible, (show: boolean, index: number) => {
          GridItem() {
            Stack() {
              // 地鼠洞
              Ellipse()
                .width(90)
                .height(45)
                .backgroundColor('#5D4037')
                .shadow({ radius: 5, color: '#00000033', offsetX: 0, offsetY: 3 })
                .position({ bottom: 0 });

              // 地鼠
              if (show && !this.isPaused) {
                Text("🐭")
                  .fontSize(50)
                  .position({ bottom: 45 })
                  .onClick(() => this.hitMole(index));
              }
            }
            .width(110)
            .height(110)
            .alignContent(Alignment.Bottom)
            .backgroundColor('#D7CCC8')
            .borderRadius(16)
            .margin(5);
          }
        });
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .width('92%')
      .aspectRatio(1)
      .backgroundColor('#8BC34A')
      .borderRadius(20)
      .padding(15)
      .margin({ top: 30 })
      .flexGrow(1); // 占满剩余空间

      // 底部功能栏（新增）
      Column() {
        // 第一行：连击计数
        Row() {
          Text(`连击: x${this.comboCount}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF5722');
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 10 });

        // 第二行：锤子展示 + 功能按钮
        Row() {
          // 当前锤子
          Row() {
            Text(this.selectedHammer.icon)
              .fontSize(30);
            Column() {
              Text(this.selectedHammer.name)
                .fontSize(16)
                .fontWeight(FontWeight.Bold);
              Text(`倍率 x${this.selectedHammer.scoreMultiplier}`)
                .fontSize(12)
                .fontColor('#666');
            }
            .margin({ left: 8 });
          }
          .padding(10)
          .backgroundColor('#F5F5F5')
          .borderRadius(10)
          .flexGrow(1);

          // 暂停/继续按钮
          Button(this.isPaused ? "继续" : "暂停")
            .width(80)
            .height(40)
            .fontSize(16)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .margin({ left: 10 })
            .onClick(() => this.togglePause());

          // 退出按钮
          Button("退出")
            .width(80)
            .height(40)
            .fontSize(16)
            .backgroundColor('#F44336')
            .borderRadius(8)
            .margin({ left: 10 })
            .onClick(() => {
              this.restartGame();
              this.currentPage = "login";
            });
        }
        .width('100%')
        .padding(10);
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 0, bottomRight: 0 })
      .padding(15);
    }
    .width('100%')
    .height('100%');
  }

  // 结果页
  @Builder
  resultPage() {
    Column() {
      if (this.levelFailed) {
        // 失败页
        Text("😢 关卡失败")
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E53935')
          .margin({ top: 100, bottom: 30 });

        Text(`需达到本关80%分数才可继续`)
          .fontSize(20)
          .margin({ bottom: 10 });

        Text(`当前得分: ${this.score}`)
          .fontSize(20)
          .margin({ bottom: 40 });
      } else if (this.level > 3) {
        // 通关页
        Text("🎉 全部通关！")
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .margin({ top: 100, bottom: 30 });

        Text(`最终得分: ${this.score}`)
          .fontSize(28)
          .margin({ bottom: 40 });
      } else {
        // 关卡通过
        Text("✅ 关卡通过")
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .margin({ top: 100, bottom: 30 });

        Text(`进入下一关`)
          .fontSize(24)
          .margin({ bottom: 15 });

        Text(`得分: ${this.score}`)
          .fontSize(20)
          .margin({ bottom: 40 });
      }

      Button("重新开始")
        .width('80%')
        .height(55)
        .fontSize(22)
        .backgroundColor('#2196F3')
        .borderRadius(12)
        .onClick(() => {
          this.restartGame();
          this.currentPage = "login";
        });

      if (!this.levelFailed && this.level <= 3) {
        Button("下一关")
          .width('80%')
          .height(55)
          .fontSize(22)
          .backgroundColor('#FF9800')
          .borderRadius(12)
          .margin({ top: 20 })
          .onClick(() => {
            this.level += 1;
            this.score = 0;
            this.comboCount = 0;
            this.currentPage = "countdown";
            this.startCountdown();
          });
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }

  // 倒计时逻辑
  startCountdown() {
    this.countdownNum = 3;
    let countTimer = setInterval(() => {
      if (this.countdownNum > 1) {
        this.countdownNum -= 1;
      } else {
        clearInterval(countTimer);
        this.currentPage = "game";
        this.startLevel();
      }
    }, 1000);
  }

  // 开始关卡
  startLevel() {
    const config: LevelConfig = this.levelConfig[this.level - 1];
    this.timeLeft = config.time;
    this.moleVisible = [false, false, false, false, false, false, false, false, false];
    this.isPaused = false;
    this.comboCount = 0;

    clearInterval(this.timerInterval);
    clearInterval(this.moleInterval);

    // 倒计时
    this.timerInterval = setInterval(() => {
      if (!this.isPaused && this.timeLeft > 0) {
        this.timeLeft -= 1;
      } else if (this.timeLeft <= 0) {
        clearInterval(this.timerInterval);
        clearInterval(this.moleInterval);
        this.checkLevelPass();
      }
    }, 1000);

    // 地鼠随机出现
    this.moleInterval = setInterval(() => {
      if (!this.isPaused) {
        this.moleVisible = this.moleVisible.map(() => false);
        let randomPos = Math.floor(Math.random() * 9);
        this.moleVisible[randomPos] = true;
      }
    }, config.speed);
  }

  // 打地鼠
  hitMole(index: number) {
    if (this.moleVisible[index] && !this.isPaused) {
      let baseScore = 10;
      let comboBonus = Math.min(this.comboCount * 0.1, 0.5);
      let finalScore = Math.floor(baseScore * this.selectedHammer.scoreMultiplier * (1 + comboBonus));
      this.score += finalScore;

      this.comboCount += 1;
      this.moleVisible[index] = false;
    }
  }

  // 切换暂停状态
  togglePause() {
    this.isPaused = !this.isPaused;
  }

  // 检查关卡通过（80% 规则）
  checkLevelPass() {
    const config = this.levelConfig[this.level - 1];
    const required = config.maxScore * 0.8;

    if (this.score >= required) {
      this.levelFailed = false;
      if (this.level >= 3) {
        this.level++;
        this.currentPage = "result";
      } else {
        this.currentPage = "result";
      }
    } else {
      this.levelFailed = true;
      this.currentPage = "result";
    }
  }

  // 重新开始游戏
  restartGame() {
    clearInterval(this.moleInterval);
    clearInterval(this.timerInterval);

    this.score = 0;
    this.level = 1;
    this.timeLeft = 30;
    this.gameStart = false;
    this.gameOver = false;
    this.levelFailed = false;
    this.moleVisible = [false, false, false, false, false, false, false, false, false];
    this.comboCount = 0;
    this.isPaused = false;
  }
}