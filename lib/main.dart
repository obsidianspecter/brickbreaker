import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';

void main() {
  runApp(BrickBreakerApp());
}

class BrickBreakerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: BrickBreakerGame(),
    );
  }
}

class BrickBreakerGame extends StatefulWidget {
  @override
  _BrickBreakerGameState createState() => _BrickBreakerGameState();
}

class _BrickBreakerGameState extends State<BrickBreakerGame> {
  // Ball properties
  double ballX = 0;
  double ballY = 0;
  double ballXDirection = 1;
  double ballYDirection = -1;
  double ballSpeed = 0.1;

  // Paddle properties
  double paddleX = 0;
  double paddleWidth = 0.3;

  // Brick properties
  List<List<int>> bricks = [];
  int bricksLeft = 0;

  // Gradient background colors
  List<Color> _gradientColors = [Colors.blue, Colors.purple];
  int _gradientIndex = 0;

  // Score tracking
  int score = 0;

  // Game state
  bool gameRunning = false;
  bool gamePaused = false;

  // Power-up properties
  bool powerUpActive = false;
  double powerUpX = 0;
  double powerUpY = -1;

  @override
  void initState() {
    super.initState();
    resetGame();
    startGradientTransition();
  }

  void resetGame() {
    setState(() {
      ballX = 0;
      ballY = 0;
      ballXDirection = 1;
      ballYDirection = -1;
      ballSpeed = 0.01;
      paddleX = 0;
      bricksLeft = 30; // 5 rows, 6 columns
      score = 0;
      gameRunning = true;
      gamePaused = false;
      powerUpActive = false;
      bricks = List.generate(5, (row) {
        return List.generate(6, (col) {
          return Random().nextBool() ? 1 : 0; // Randomly activated bricks
        });
      });
    });
    startGame();
  }

  void startGame() {
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!gameRunning) {
        timer.cancel();
        return;
      }
      setState(() {
        moveBall();
      });
    });
  }

  void startGradientTransition() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        _gradientIndex = (_gradientIndex + 1) % _gradientColors.length;
      });
    });
  }

  void moveBall() {
    ballX += ballSpeed * ballXDirection;
    ballY += ballSpeed * ballYDirection;

    // Ball collision with walls
    if (ballX <= -1 || ballX >= 1) ballXDirection *= -1; // Left/right walls
    if (ballY <= -1) ballYDirection *= -1; // Top wall

    // Paddle collision
    if (ballY >= 0.9 &&
        ballX >= paddleX - paddleWidth / 2 &&
        ballX <= paddleX + paddleWidth / 2) {
      ballYDirection *= -1;
      ballSpeed += 0.002; // Increase speed on paddle hit
    }

    // Power-up collision with paddle
    if (powerUpActive &&
        ballY >= powerUpY - 0.05 &&
        ballX >= powerUpX - 0.1 &&
        ballX <= powerUpX + 0.1) {
      setState(() {
        powerUpActive = false;
        paddleWidth += 0.1; // Increase paddle width on power-up
      });
    }

    // Brick collision
    for (int row = 0; row < bricks.length; row++) {
      for (int col = 0; col < bricks[row].length; col++) {
        if (bricks[row][col] == 1) {
          double brickX = col / 6 * 2 - 1 + 0.16;
          double brickY = row / 5 * 0.5 - 0.8;
          if ((ballX - brickX).abs() < 0.1 && (ballY - brickY).abs() < 0.1) {
            setState(() {
              bricks[row][col] = 0; // Break the brick
              score += 10; // Increase score for breaking a brick
              bricksLeft--;
              ballYDirection *= -1; // Reverse ball direction
            });
            if (Random().nextDouble() < 0.2) {
              // 20% chance for a power-up
              spawnPowerUp(brickX, brickY);
            }
          }
        }
      }
    }

    // Check for game over
    if (ballY > 1) {
      gameRunning = false;
      showGameOverDialog();
    }

    // Check for level completion
    if (bricksLeft == 0) {
      gameRunning = false;
      showLevelCompleteDialog();
    }
  }

  void spawnPowerUp(double brickX, double brickY) {
    setState(() {
      powerUpActive = true;
      powerUpX = brickX;
      powerUpY = brickY;
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Game Over'),
        content: Text('Your score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: Text('Restart'),
          ),
        ],
      ),
    );
  }

  void showLevelCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Level Complete'),
        content: Text('Your score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: Text('Next Level'),
          ),
        ],
      ),
    );
  }

  void movePaddle(DragUpdateDetails details) {
    setState(() {
      paddleX += details.primaryDelta! / MediaQuery.of(context).size.width * 2;
      if (paddleX - paddleWidth / 2 < -1) paddleX = -1 + paddleWidth / 2;
      if (paddleX + paddleWidth / 2 > 1) paddleX = 1 - paddleWidth / 2;
    });
  }

  Widget buildGlassEffect({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: movePaddle,
        child: AnimatedContainer(
          duration: Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _gradientColors[_gradientIndex],
                _gradientColors[(_gradientIndex + 1) % _gradientColors.length]
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Ball
              Align(
                alignment: Alignment(ballX, ballY),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Paddle
              Align(
                alignment: Alignment(paddleX, 0.9),
                child: buildGlassEffect(
                  child: Container(
                    width: MediaQuery.of(context).size.width * paddleWidth,
                    height: 10,
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Power-up
              if (powerUpActive)
                Align(
                  alignment: Alignment(powerUpX, powerUpY),
                  child: buildGlassEffect(
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              // Bricks
              ...bricks.asMap().entries.expand((rowEntry) {
                int row = rowEntry.key;
                return rowEntry.value.asMap().entries.map((colEntry) {
                  int col = colEntry.key;
                  if (colEntry.value == 1) {
                    return Align(
                      alignment: Alignment(
                        col / 6 * 2 - 1 + 0.16,
                        row / 5 * 0.5 - 0.8,
                      ),
                      child: buildGlassEffect(
                        child: Container(
                          width: MediaQuery.of(context).size.width / 6 - 10,
                          height: 20,
                          color: Colors.transparent,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }).toList();
              }).toList(),
              // Score
              Positioned(
                top: 50,
                left: 20,
                child: Text('Score: $score',
                    style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
