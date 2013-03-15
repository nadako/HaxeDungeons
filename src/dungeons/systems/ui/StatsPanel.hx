package dungeons.systems.ui;

import nme.display.Sprite;

import dungeons.components.Fighter;
import dungeons.components.Health;

import ru.stablex.ui.widgets.Text;
import ru.stablex.ui.UIBuilder;

class StatsPanel extends Sprite
{
    private var healthLabel:Text;
    private var fighterLabel:Text;

    public function new()
    {
        super();

        mouseChildren = false;

        healthLabel = UIBuilder.getAs("statsPanel.healthLabel", Text);
        fighterLabel = UIBuilder.getAs("statsPanel.fighterLabel", Text);
    }

    public function update(health:Health, fighter:Fighter):Void
    {
        healthLabel.text = "HP: " + health.currentHP + "/" + health.maxHP;
        fighterLabel.text = "PWR: " + fighter.power + ", DEF: " + fighter.defense;
    }
}
