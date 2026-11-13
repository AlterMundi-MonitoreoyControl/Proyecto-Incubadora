"""Regresión de posiciones globales; ejecutar con el Python de FreeCAD."""
import tempfile
import unittest
from pathlib import Path

import FreeCAD as App
import Part

from export_manual import check_same_geometry, export_document, summary, world_shape


class GlobalPlacementTest(unittest.TestCase):
    def setUp(self):
        self.doc = App.newDocument('RegressionExport')
        self.root = self.doc.addObject('App::Part', 'despiece_libreincu')
        self.root.Placement = App.Placement(App.Vector(10, 20, 30),
                                           App.Rotation(App.Vector(0, 0, 1), 35))
        parent = self.doc.addObject('App::Part', 'deflector_inferior')
        self.root.addObject(parent)
        parent.Placement = App.Placement(App.Vector(0, 180, 600),
                                        App.Rotation(App.Vector(1, 0, 0), 160))
        inner = self.doc.addObject('App::Part', 'deflector_pliegue')
        parent.addObject(inner)
        inner.Placement = App.Placement(App.Vector(7, -4, 12),
                                       App.Rotation(App.Vector(0, 1, 0), 23))
        self.leaf = self.doc.addObject('Part::Feature', 'deflector_pieza_001')
        inner.addObject(self.leaf)
        self.leaf.Shape = Part.makeBox(17, 29, 3)
        self.leaf.Placement = App.Placement(App.Vector(2, 8, 5),
                                           App.Rotation(App.Vector(0, 0, 1), 19))
        # El resultado esperado se construye con los cuatro Placement explícitos,
        # sin llamar al helper ni a getGlobalPlacement().
        placement = self.root.Placement.multiply(parent.Placement).multiply(
            inner.Placement).multiply(self.leaf.Placement)
        self.expected = Part.makeBox(17, 29, 3)
        self.expected.Placement = placement
        for group_name in ('bandeja_1', 'husillo_8mm_400mm'):
            group = self.doc.addObject('App::Part', group_name)
            self.root.addObject(group)
            obj = self.doc.addObject('Part::Feature', group_name + '_pieza_001')
            group.addObject(obj)
            obj.Shape = Part.makeBox(2, 3, 4)
        self.doc.recompute()

    def tearDown(self):
        App.closeDocument(self.doc.Name)

    def test_nested_group_and_leaf_placements(self):
        shape = world_shape(self.leaf)
        check_same_geometry(summary(self.expected), summary(shape), 'global')
        self.assertAlmostEqual(self.expected.common(shape).Volume,
                               self.expected.Volume, places=6)
        # El método anterior debe ser detectado, aunque el sólido sea válido.
        self.assertTrue(self.leaf.Shape.isValid())
        enclosure = Part.makeBox(3000, 3000, 3000, App.Vector(-1500, -1500, -1500))
        # Ni el volumen ni los límites del conjunto detectan el error interno.
        check_same_geometry(
            summary(Part.makeCompound([enclosure, self.expected])),
            summary(Part.makeCompound([enclosure, self.leaf.Shape])), 'conjunto')
        with self.assertRaises(RuntimeError):
            check_same_geometry(summary(self.expected), summary(self.leaf.Shape), 'local')

    def test_step_roundtrip_preserves_global_geometry_and_source(self):
        placements = {o.Name: str(o.Placement) for o in self.doc.Objects}
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'source.FCStd'
            self.doc.saveAs(str(source))
            source_bytes = source.read_bytes()
            manifest = export_document(self.doc, source, Path(tmp) / 'steps')
            self.assertEqual(len(manifest['exportaciones']), 3)
            full = manifest['exportaciones'][0]
            imported = Part.read(str(Path(tmp) / 'steps' / full['archivo']))
            # Comparar por coincidencia geométrica, sin depender del orden STEP.
            matches = [s for s in imported.Solids if abs(
                s.common(self.expected).Volume - self.expected.Volume) < 1e-5]
            self.assertEqual(len(matches), 1)
            self.assertEqual(source.read_bytes(), source_bytes)
        self.assertEqual({o.Name: str(o.Placement) for o in self.doc.Objects}, placements)


if __name__ == '__main__':
    unittest.main()
