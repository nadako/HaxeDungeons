package dungeons.systems.ui;

import dungeons.components.Fighter;
import dungeons.components.Health;

import com.bit101.components.Panel;
import com.bit101.components.Label;
import com.bit101.components.VBox;

class StatsPanel extends Panel
{
    private var healthLabel:Label;
    private var fighterLabel:Label;

    public function new()
    {
        super();
        var vbox:VBox = new VBox(this);
        healthLabel = new Label(vbox);
        fighterLabel = new Label(vbox);
        setSize(75, 50);
    }

    public function update(health:Health, fighter:Fighter):Void
    {
        healthLabel.text = "HP: " + health.currentHP + "/" + health.maxHP;
        fighterLabel.text = "PWR: " + fighter.power + ", DEF: " + fighter.defense;
    }
}
