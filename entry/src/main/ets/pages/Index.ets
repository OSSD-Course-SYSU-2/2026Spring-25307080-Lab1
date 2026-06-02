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
  @State comboCount: number = 0; // 连续打中连击数
  @State isPaused: boolean = false;

  // 屏幕宽度自适应
  @StorageLink('windowWidth') winWidth: number = 0;
  isPad(): boolean {
    return this.winWidth > 600;
  }
  getGridSize(): number {
    return this.isPad() ? 130 : 110;
  }
  getFontSize(size: number): number {
    return this.isPad() ? size * 1.3 : size;
  }

  // 锤子列表
  hammerList: Hammer[] = [
    { id: 1, name: "木锤", icon: "🔨", color: "#8D6E63", scoreMultiplier: 1.0 },
    { id: 2, name: "金锤", icon: "⚒️", color: "#FFD700", scoreMultiplier: 1.5 },
    { id: 3, name: "雷神锤", icon: "🛠️", color: "#4A90E2", scoreMultiplier: 2.0 }
  ];

  // 关卡配置
  levelConfig: LevelConfig[] = [
    { time: 30, speed: 1000, maxScore: 300 },
    { time: 30, speed: 800, maxScore: 350 },
    { time: 30, speed: 550, maxScore: 400 }
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
        .fontSize(this.getFontSize(40))
        .fontWeight(FontWeight.Bold)
        .fontColor('#E65100')
        .margin({ top: 120, bottom: 60 });

      TextInput({ placeholder: "请输入用户名" })
        .width('80%')
        .height(50)
        .fontSize(this.getFontSize(18))
        .margin({ bottom: 30 })
        .onChange((val: string) => {
          this.username = val;
        });

      Button("进入游戏")
        .width('80%')
        .height(55)
        .fontSize(this.getFontSize(22))
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
        .fontSize(this.getFontSize(32))
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 40 });

      Grid() {
        ForEach(this.hammerList, (hammer: Hammer) => {
          GridItem() {
            Column() {
              Text(hammer.icon)
                .fontSize(this.getFontSize(60));
              Text(hammer.name)
                .fontSize(this.getFontSize(20))
                .margin({ top: 10 });
              Text(`倍率 x${hammer.scoreMultiplier}`)
                .fontSize(this.getFontSize(14))
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
        .fontSize(this.getFontSize(22))
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
        .fontSize(this.getFontSize(120))
        .fontWeight(FontWeight.Bold)
        .fontColor('#E53935')
        .animation({ duration: 800, curve: Curve.EaseOut });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  // 游戏页面【关键修改：Grid取消flexGrow，底部连击固定显示】
  @Builder
  gamePage() {
    Column() {
      // 顶部信息栏
      Row() {
        Text(`玩家: ${this.username}`)
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold);
        Text(`关卡: ${this.level}`)
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 });
        Text(`分数: ${this.score}`)
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 });
        Text(`时间: ${this.timeLeft}s`)
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 });
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(12)
      .backgroundColor('#FFF8E1')
      .borderRadius(16);

      // 3*3地洞网格【删掉flexGrow，不再抢占底部空间】
      Grid() {
        ForEach(this.moleVisible, (show: boolean, index: number) => {
          GridItem() {
            Stack() {
              Ellipse()
                .width(this.isPad() ? 100 : 80)
                .height(this.isPad() ? 50 : 40)
                .backgroundColor('#5D4037')
                .shadow({ radius: 5, color: '#00000033', offsetX: 0, offsetY: 3 })
                .position({ bottom: 0 });

              if (show && !this.isPaused) {
                Text("🐭")
                  .fontSize(this.getFontSize(50))
                  .position({ bottom: this.isPad() ? 50 : 45 })
                  .onClick(() => this.hitMole(index));
              }
            }
            .width(this.getGridSize())
            .height(this.getGridSize())
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
      .backgroundColor('#8BC34A')
      .borderRadius(20)
      .padding(15)
      .margin({ top: 30 });

      Blank().layoutWeight(1); // 空白占位，把底部控件压在最下面

      // ==========【连击文字：现在固定在按钮上方，必显示】==========
      Text(`🔥当前连击倍数：x${this.comboCount}`)
        .fontSize(this.getFontSize(26))
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF3D00')
        .margin({top:8,bottom:8});

      // 底部按钮栏：锤子信息+暂停+退出
      Row() {
        Row() {
          Text(this.selectedHammer.icon)
            .fontSize(this.getFontSize(30));
          Column() {
            Text(this.selectedHammer.name)
              .fontSize(this.getFontSize(16))
              .fontWeight(FontWeight.Bold);
            Text(`倍率 x${this.selectedHammer.scoreMultiplier}`)
              .fontSize(this.getFontSize(12))
              .fontColor('#666');
          }
          .margin({ left: 8 });
        }
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        .flexGrow(1);

        Button(this.isPaused ? "继续" : "暂停")
          .width(80)
          .height(40)
          .fontSize(this.getFontSize(16))
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .margin({ left: 10 })
          .onClick(() => this.togglePause());

        Button("退出")
          .width(80)
          .height(40)
          .fontSize(this.getFontSize(16))
          .backgroundColor('#F44336')
          .borderRadius(8)
          .margin({ left: 10 })
          .onClick(() => {
            this.restartGame();
            this.currentPage = "login";
          });
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 });
    }
    .width('100%')
    .height('100%');
  }

  // 结果页
  @Builder
  resultPage() {
    Column() {
      if (this.levelFailed) {
        Text("😢 关卡失败")
          .fontSize(this.getFontSize(36))
          .fontWeight(FontWeight.Bold)
          .fontColor('#E53935')
          .margin({ top: 100, bottom: 30 });
        Text(`需达到本关80%分数才可继续`)
          .fontSize(this.getFontSize(20))
          .margin({ bottom: 10 });
        Text(`当前得分: ${this.score}`)
          .fontSize(this.getFontSize(20))
          .margin({ bottom: 40 });
      } else if (this.level > 3) {
        Text("🎉 全部通关！")
          .fontSize(this.getFontSize(36))
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .margin({ top: 100, bottom: 30 });
        Text(`最终得分: ${this.score}`)
          .fontSize(this.getFontSize(28))
          .margin({ bottom: 40 });
      } else {
        Text("✅ 关卡通过")
          .fontSize(this.getFontSize(36))
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .margin({ top: 100, bottom: 30 });
        Text(`进入下一关`)
          .fontSize(this.getFontSize(24))
          .margin({ bottom: 15 });
        Text(`得分: ${this.score}`)
          .fontSize(this.getFontSize(20))
          .margin({ bottom: 40 });
      }

      Button("重新开始")
        .width('80%')
        .height(55)
        .fontSize(this.getFontSize(22))
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
          .fontSize(this.getFontSize(22))
          .backgroundColor('#FF9800')
          .borderRadius(12)
          .margin({ top: 20 })
          .onClick(() => {
            this.level += 1;
            this.score = 0;
            this.comboCount = 0; // 换关卡清空连击
            this.currentPage = "countdown";
            this.startCountdown();
          });
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center);
  }

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

  startLevel() {
    const config: LevelConfig = this.levelConfig[this.level - 1];
    this.timeLeft = config.time;
    this.moleVisible = [false, false, false, false, false, false, false, false, false];
    this.isPaused = false;
    this.comboCount = 0; // 开局连击清零
    clearInterval(this.timerInterval);
    clearInterval(this.moleInterval);

    this.timerInterval = setInterval(() => {
      if (!this.isPaused && this.timeLeft > 0) {
        this.timeLeft -= 1;
      } else if (this.timeLeft <= 0) {
        clearInterval(this.timerInterval);
        clearInterval(this.moleInterval);
        this.checkLevelPass();
      }
    }, 1000);

    this.moleInterval = setInterval(() => {
      if (!this.isPaused) {
        this.moleVisible = this.moleVisible.map(() => false);
        let randomPos = Math.floor(Math.random() * 9);
        this.moleVisible[randomPos] = true;
      }
    }, config.speed);
  }

  // 打中地鼠：连续打中combo+1，地鼠消失重置连击
  hitMole(index: number) {
    if (this.moleVisible[index] && !this.isPaused) {
      let baseScore = 10;
      // 连击加分，连击越高收益越高
      let comboBonus = Math.min(this.comboCount * 0.1, 0.5);
      let finalScore = Math.floor(baseScore * this.selectedHammer.scoreMultiplier * (1 + comboBonus));
      this.score += finalScore;
      this.comboCount += 1;
      this.moleVisible[index] = false;
    }
  }

  togglePause() {
    this.isPaused = !this.isPaused;
  }

  checkLevelPass() {
    const config = this.levelConfig[this.level - 1];
    const required = config.maxScore * 0.8;
    if (this.score >= required) {
      this.levelFailed = false;
      if (this.level >= 3) this.level++;
    } else {
      this.levelFailed = true;
    }
    this.currentPage = "result";
  }

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