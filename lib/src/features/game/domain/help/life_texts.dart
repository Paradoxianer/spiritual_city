import 'help_content.dart';

/// The life story (📜) in short CV-style lines when texts are on
/// (playtest 2026-10-31) – one per life event, keyed by its id.
abstract final class LifeTexts {
  static const Map<String, Tr> events = {
    'best_friends_childhood': Tr('Beste Freunde in der Nachbarschaft', 'Best friends in the neighbourhood', es: 'Mejores amigos en el vecindario', fr: 'Meilleurs amis dans le voisinage', pt: 'Melhores amigos na vizinhança'),
    'playground_fun': Tr('Glückliche Stunden auf dem Spielplatz', 'Happy hours at the playground', es: 'Horas felices en el parque', fr: 'Heures heureuses au terrain de jeux', pt: 'Horas felizes no parquinho'),
    'sports_club': Tr('Im Sportverein, mit Pokal', 'In a sports club, won a trophy', es: 'En un club deportivo, ganó un trofeo', fr: 'Dans un club de sport, a gagné une coupe', pt: 'Num clube esportivo, ganhou um troféu'),
    'minor_sibling_rivalry': Tr('Streit unter Geschwistern', 'Squabbles between siblings', es: 'Peleas entre hermanos', fr: 'Disputes entre frères et sœurs', pt: 'Brigas entre irmãos'),
    'first_crush': Tr('Erste Schwärmerei', 'First crush', es: 'Primer enamoramiento', fr: 'Premier béguin', pt: 'Primeira paixão'),
    'circle_of_friends': Tr('Ein fröhlicher Freundeskreis', 'A cheerful circle of friends', es: 'Un grupo de amigos alegre', fr: 'Une joyeuse bande d’amis', pt: 'Uma turma de amigos alegre'),
    'small_argument_with_friends': Tr('Krach mit Freunden', 'A falling-out with friends', es: 'Una pelea con amigos', fr: 'Une dispute avec des amis', pt: 'Uma briga com amigos'),
    'steady_friendships_now': Tr('Treue Freundschaften', 'Steady friendships', es: 'Amistades fieles', fr: 'Des amitiés fidèles', pt: 'Amizades fiéis'),
    'occasional_loneliness': Tr('Fühlt sich manchmal einsam', 'Feels lonely at times', es: 'A veces se siente solo', fr: 'Se sent parfois seul', pt: 'Às vezes se sente sozinho'),
    'neglect': Tr('Als Kind vernachlässigt', 'Neglected as a child', es: 'Descuidado de niño', fr: 'Négligé dans l’enfance', pt: 'Negligenciado na infância'),
    'parents_separation': Tr('Die Eltern haben sich getrennt', 'The parents separated', es: 'Los padres se separaron', fr: 'Les parents se sont séparés', pt: 'Os pais se separaram'),
    'failed_relationship': Tr('Eine Beziehung ist zerbrochen', 'A relationship broke apart', es: 'Una relación se rompió', fr: 'Une relation s’est brisée', pt: 'Um relacionamento terminou'),
    'sheltered_childhood': Tr('Eine behütete Kindheit', 'A sheltered childhood', es: 'Una infancia protegida', fr: 'Une enfance protégée', pt: 'Uma infância protegida'),
    'first_love': Tr('Die erste Liebe', 'First love', es: 'El primer amor', fr: 'Le premier amour', pt: 'O primeiro amor'),
    'happy_relationship': Tr('Eine glückliche Ehe', 'A happy marriage', es: 'Un matrimonio feliz', fr: 'Un mariage heureux', pt: 'Um casamento feliz'),
    'lost_pet': Tr('Das Haustier ist gestorben', 'A beloved pet died', es: 'Murió su mascota', fr: 'Son animal de compagnie est mort', pt: 'O animal de estimação morreu'),
    'moved_away_lost_friends': Tr('Umgezogen und Freunde verloren', 'Moved away and lost friends', es: 'Se mudó y perdió amigos', fr: 'A déménagé et perdu ses amis', pt: 'Mudou-se e perdeu amigos'),
    'family_illness': Tr('Schwere Krankheit in der Familie', 'Serious illness in the family', es: 'Enfermedad grave en la familia', fr: 'Grave maladie dans la famille', pt: 'Doença grave na família'),
    'loss_of_parent': Tr('Ein Elternteil ist gestorben', 'Lost a parent', es: 'Perdió a uno de sus padres', fr: 'A perdu un de ses parents', pt: 'Perdeu um dos pais'),
    'violent_loss': Tr('Einen Menschen gewaltsam verloren', 'Lost someone to violence', es: 'Perdió a alguien por la violencia', fr: 'A perdu un proche dans la violence', pt: 'Perdeu alguém para a violência'),
    'normal_childhood_illness': Tr('Die üblichen Kinderkrankheiten', 'The usual childhood illnesses', es: 'Las enfermedades típicas de la infancia', fr: 'Les maladies d’enfance habituelles', pt: 'As doenças comuns da infância'),
    'active_and_fit': Tr('Sportlich und fit', 'Active and fit', es: 'Activo y en forma', fr: 'Sportif et en forme', pt: 'Ativo e em forma'),
    'robust_health': Tr('Kerngesund', 'Robust health', es: 'Salud de hierro', fr: 'Une santé solide', pt: 'Saúde de ferro'),
    'minor_health_worries': Tr('Kleinere gesundheitliche Sorgen', 'Minor health worries', es: 'Pequeñas preocupaciones de salud', fr: 'De petits soucis de santé', pt: 'Pequenas preocupações de saúde'),
    'alcohol_abuse': Tr('Probleme mit Alkohol', 'Problems with alcohol', es: 'Problemas con el alcohol', fr: 'Des problèmes d’alcool', pt: 'Problemas com álcool'),
    'drugs': Tr('In Drogen abgerutscht', 'Slipped into drugs', es: 'Cayó en las drogas', fr: 'Tombé dans la drogue', pt: 'Caiu nas drogas'),
    'imprisonment': Tr('Im Gefängnis gewesen', 'Spent time in prison', es: 'Estuvo en la cárcel', fr: 'A fait de la prison', pt: 'Esteve preso'),
    'pocket_money': Tr('Taschengeld gespart', 'Saved pocket money', es: 'Ahorró su paga', fr: 'A économisé son argent de poche', pt: 'Juntou a mesada'),
    'finished_school_ok': Tr('Schule gut abgeschlossen', 'Finished school well', es: 'Terminó bien la escuela', fr: 'A bien terminé l’école', pt: 'Terminou bem a escola'),
    'enjoyed_school_days': Tr('Gern zur Schule gegangen', 'Enjoyed school days', es: 'Disfrutó la escuela', fr: 'A aimé l’école', pt: 'Gostava da escola'),
    'normal_job': Tr('Ein fester Job', 'A steady job', es: 'Un trabajo estable', fr: 'Un emploi stable', pt: 'Um emprego estável'),
    'had_to_budget': Tr('Musste jeden Euro umdrehen', 'Had to count every penny', es: 'Tuvo que contar cada céntimo', fr: 'A dû compter chaque centime', pt: 'Teve que contar cada centavo'),
    'unemployment': Tr('Arbeit verloren', 'Lost their job', es: 'Perdió el trabajo', fr: 'A perdu son emploi', pt: 'Perdeu o emprego'),
    'debt': Tr('Schulden', 'Debt', es: 'Deudas', fr: 'Des dettes', pt: 'Dívidas'),
    'career_success': Tr('Beruflicher Erfolg', 'Success at work', es: 'Éxito profesional', fr: 'Réussite professionnelle', pt: 'Sucesso profissional'),
    'inheritance': Tr('Eine Erbschaft', 'An inheritance', es: 'Una herencia', fr: 'Un héritage', pt: 'Uma herança'),
    'sunday_school': Tr('In der Kinderkirche', 'Went to Sunday school', es: 'Fue a la escuela dominical', fr: 'Est allé à l’école du dimanche', pt: 'Frequentou a escola dominical'),
    'said_grace_at_home': Tr('Zu Hause wurde vor dem Essen gebetet', 'Grace was said at home', es: 'En casa se bendecía la mesa', fr: 'On disait le bénédicité à la maison', pt: 'Em casa se orava antes das refeições'),
    'questioned_faith_as_teen': Tr('Als Jugendlicher am Glauben gezweifelt', 'Questioned faith as a teenager', es: 'Cuestionó la fe en la adolescencia', fr: 'A douté de la foi à l’adolescence', pt: 'Questionou a fé na adolescência'),
    'church_disappointment': Tr('Von der Kirche enttäuscht', 'Disappointed by the church', es: 'Decepcionado por la iglesia', fr: 'Déçu par l’Église', pt: 'Decepcionado com a igreja'),
    'unanswered_prayer': Tr('Ein Gebet blieb unbeantwortet', 'A prayer went unanswered', es: 'Una oración quedó sin respuesta', fr: 'Une prière est restée sans réponse', pt: 'Uma oração ficou sem resposta'),
    'conversion_experience': Tr('Gott ganz nah erlebt', 'Experienced God very close', es: 'Experimentó a Dios muy cerca', fr: 'A vécu Dieu tout proche', pt: 'Experimentou Deus bem perto'),
    'answered_prayer': Tr('Ein Gebet wurde erhört', 'A prayer was answered', es: 'Una oración fue respondida', fr: 'Une prière a été exaucée', pt: 'Uma oração foi respondida'),
    'first_bible_study': Tr('Der erste Bibelkreis', 'The first Bible study', es: 'El primer estudio bíblico', fr: 'La première étude biblique', pt: 'O primeiro estudo bíblico'),
    'new_church_friends': Tr('Neue Freunde in der Gemeinde', 'New friends at church', es: 'Nuevos amigos en la iglesia', fr: 'De nouveaux amis à l’église', pt: 'Novos amigos na igreja'),
    'baptism': Tr('Getauft', 'Baptised', es: 'Bautizado', fr: 'Baptisé', pt: 'Batizado'),
    'shared_faith_with_someone': Tr('Hat jemandem vom Glauben erzählt', 'Shared their faith with someone', es: 'Compartió su fe con alguien', fr: 'A partagé sa foi avec quelqu’un', pt: 'Compartilhou a fé com alguém'),
    'grown_through_setback': Tr('An einem Rückschlag im Glauben gewachsen', 'Grew in faith through a setback', es: 'Creció en la fe a través de un revés', fr: 'A grandi dans la foi à travers un revers', pt: 'Cresceu na fé através de um revés'),
    'doubted_if_it_was_real': Tr('Zweifelt, ob es echt ist', 'Doubts whether it is real', es: 'Duda de si es real', fr: 'Doute que ce soit vrai', pt: 'Duvida se é real'),
    'small_group_conflict': Tr('Streit im Hauskreis', 'Conflict in the small group', es: 'Conflicto en el grupo pequeño', fr: 'Un conflit dans le groupe de maison', pt: 'Conflito no pequeno grupo'),
  };

  static const Tr born = Tr('Geboren', 'Born', es: 'Nació', fr: 'Naissance', pt: 'Nasceu');
  static const Tr hidden = Tr('Mehr erzählt die Person noch nicht', 'They have not told more yet', es: 'Aún no ha contado más', fr: 'N’en a pas encore raconté plus', pt: 'Ainda não contou mais');
  static const Tr resolved = Tr('Mit deiner Hilfe verarbeitet', 'Worked through with your help', es: 'Superado con tu ayuda', fr: 'Surmonté avec ton aide', pt: 'Superado com sua ajuda');
  static const Tr converted = Tr('Ist Christ geworden', 'Became a Christian', es: 'Se hizo cristiano', fr: 'Est devenu chrétien', pt: 'Tornou-se cristão');
  static const Tr today = Tr('Heute', 'Today', es: 'Hoy', fr: 'Aujourd’hui', pt: 'Hoje');
  static const Tr current = Tr('darüber sprecht ihr gerade', 'you are talking about this now', es: 'de esto están hablando ahora', fr: 'c’est ce dont vous parlez maintenant', pt: 'é sobre isso que vocês estão conversando');
}
