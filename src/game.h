#pragma once
#include <string>

struct Castle {
    std::string name;
    double position; // horizontal position
    int health;
};

class Game {
public:
    Game();
    void run();

private:
    Castle castle1;
    Castle castle2;
    bool takeTurn(Castle &shooter, Castle &target);
    double computeImpact(const Castle &shooter, double angleDeg, double velocity) const;
    void draw() const;
};
