#include "game.h"
#include <cmath>
#include <iostream>
#include <limits>

namespace {
const double g = 9.81; // gravitational constant
const int kInitialHealth = 100;
const int kDamage = 50;
const double kHitTolerance = 5.0;
constexpr double kPi = 3.14159265358979323846;
}

Game::Game() {
    castle1 = {"Player 1", 0.0, kInitialHealth};
    castle2 = {"Player 2", 100.0, kInitialHealth};
}

void Game::run() {
    std::cout << "Welcome to Ballerburg!" << std::endl;
    draw();
    while (castle1.health > 0 && castle2.health > 0) {
        if (!takeTurn(castle1, castle2)) {
            break;
        }
        draw();
        if (castle2.health <= 0) {
            break;
        }
        if (!takeTurn(castle2, castle1)) {
            break;
        }
        draw();
    }

    if (castle1.health <= 0) {
        std::cout << castle2.name << " wins!" << std::endl;
    } else {
        std::cout << castle1.name << " wins!" << std::endl;
    }
}

void Game::draw() const {
    const int width = 60;
    const std::string castleLines[4] = {
        "  ^  ",
        " /#\\ ",
        "/###\\",
        "#####"
    };

    auto mapPos = [&](double pos) {
        return static_cast<int>((pos / 100.0) * (width - static_cast<int>(castleLines[0].size())));
    };
    int pos1 = mapPos(castle1.position);
    int pos2 = mapPos(castle2.position);

    for (const std::string &line : castleLines) {
        std::string out(width, ' ');
        out.replace(pos1, line.size(), line);
        out.replace(pos2, line.size(), line);
        std::cout << out << std::endl;
    }
    std::cout << std::string(width, '=') << std::endl;
    std::cout << castle1.name << " HP:" << castle1.health;
    int spacer = width - (castle1.name.size() + 4 + std::to_string(castle1.health).size() +
                          castle2.name.size() + 4 + std::to_string(castle2.health).size());
    if (spacer < 1) spacer = 1;
    std::cout << std::string(spacer, ' ');
    std::cout << castle2.name << " HP:" << castle2.health << std::endl;
}

bool Game::takeTurn(Castle &shooter, Castle &target) {
    std::cout << shooter.name << "'s turn. Enter angle (degrees) and velocity: ";
    double angle, velocity;
    if (!(std::cin >> angle >> velocity)) {
        if (std::cin.eof()) {
            std::cout << "\nInput ended. Exiting game." << std::endl;
            return false;
        }
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        std::cout << "Invalid input. Skipping turn." << std::endl;
        return true;
    }

    double impact = computeImpact(shooter, angle, velocity);
    if (std::abs(impact - target.position) <= kHitTolerance) {
        target.health -= kDamage;
        std::cout << "Hit! " << target.name << " health: " << target.health << std::endl;
    } else if ((shooter.position < target.position && impact < target.position) ||
               (shooter.position > target.position && impact > target.position)) {
        std::cout << "Shot fell short at x=" << impact << std::endl;
    } else {
        std::cout << "Shot overshot to x=" << impact << std::endl;
    }
    return true;
}

double Game::computeImpact(const Castle &shooter, double angleDeg, double velocity) const {
    double angleRad = angleDeg * kPi / 180.0;
    double range = (velocity * velocity * std::sin(2 * angleRad)) / g;
    if (shooter.position < castle2.position) {
        return shooter.position + range;
    } else {
        return shooter.position - range;
    }
}
